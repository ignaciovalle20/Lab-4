const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const { specs, swaggerUi } = require('./swagger');
const promClient = require('prom-client');
require('dotenv').config({ path: './config.env' });

const app = express();
const PORT = process.env.PORT || 5000;

// Configuración de Prometheus
const register = new promClient.Registry();

// Agregar métricas por defecto (CPU, memoria, etc.)
promClient.collectDefaultMetrics({ 
  register,
  prefix: 'tienda_online_',
});

// Métricas personalizadas
const httpRequestDuration = new promClient.Histogram({
  name: 'tienda_online_http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestTotal = new promClient.Counter({
  name: 'tienda_online_http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const dbConnectionErrors = new promClient.Counter({
  name: 'tienda_online_db_connection_errors_total',
  help: 'Total number of database connection errors'
});

const pedidosCreados = new promClient.Counter({
  name: 'tienda_online_pedidos_creados_total',
  help: 'Total number of orders created'
});

const productosConsultados = new promClient.Counter({
  name: 'tienda_online_productos_consultados_total',
  help: 'Total number of products queried'
});

const dbQueryDuration = new promClient.Histogram({
  name: 'tienda_online_db_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['query_type'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1]
});

// Registrar métricas personalizadas
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(dbConnectionErrors);
register.registerMetric(pedidosCreados);
register.registerMetric(productosConsultados);
register.registerMetric(dbQueryDuration);

// Middleware para medir duración de requests
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    
    httpRequestDuration
      .labels(req.method, route, res.statusCode)
      .observe(duration);
    
    httpRequestTotal
      .labels(req.method, route, res.statusCode)
      .inc();
  });
  
  next();
});

// Middleware
app.use(cors());
app.use(express.json());

// Configuración de Swagger
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs, {
  customSiteTitle: "Tienda Online API",
  customfavIcon: "/assets/favicon.ico",
  customCss: '.swagger-ui .topbar { display: none }',
  swaggerOptions: {
    explorer: true,
    filter: true,
    showRequestDuration: true
  }
}));

// Conexión a la base de datos
const dbConfig = {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
};

let db;

// Inicializar conexión a la base de datos con reintentos
async function initDB() {
  const maxRetries = 10;
  const retryDelay = 5000; // 5 segundos
  let retries = 0;

  while (retries < maxRetries) {
    try {
      db = await mysql.createConnection(dbConfig);
      await db.ping(); // Verificar que la conexión funciona
      console.log('Conectado a MySQL exitosamente');
      return;
    } catch (error) {
      retries++;
      console.error(`Error conectando a MySQL (intento ${retries}/${maxRetries}):`, error.message);
      dbConnectionErrors.inc();
      
      if (retries < maxRetries) {
        console.log(`Reintentando conexión en ${retryDelay/1000} segundos...`);
        await new Promise(resolve => setTimeout(resolve, retryDelay));
      } else {
        console.error('No se pudo conectar a MySQL después de', maxRetries, 'intentos');
        throw error;
      }
    }
  }
}

// Endpoint de métricas para Prometheus
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    if (db) {
      await db.ping();
      res.json({ 
        status: 'healthy', 
        database: 'connected',
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(503).json({ 
        status: 'unhealthy', 
        database: 'disconnected',
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    res.status(503).json({ 
      status: 'unhealthy', 
      database: 'error',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Rutas básicas
/**
 * @swagger
 * /:
 *   get:
 *     summary: Verificar estado de la API
 *     description: Endpoint básico para verificar que la API está funcionando
 *     tags: [General]
 *     responses:
 *       200:
 *         description: API funcionando correctamente
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 */
app.get('/', (req, res) => {
  res.json({ message: 'API de Tienda Online funcionando' });
});

// Rutas de productos
/**
 * @swagger
 * /api/productos:
 *   get:
 *     summary: Obtener todos los productos
 *     description: Recupera la lista completa de productos disponibles en la tienda
 *     tags: [Productos]
 *     responses:
 *       200:
 *         description: Lista de productos obtenida exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Producto'
 *       500:
 *         description: Error interno del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
app.get('/api/productos', async (req, res) => {
  const start = Date.now();
  try {
    const [rows] = await db.execute('SELECT * FROM productos');
    const duration = (Date.now() - start) / 1000;
    dbQueryDuration.labels('select_all_products').observe(duration);
    productosConsultados.inc(rows.length);
    res.json(rows);
  } catch (error) {
    console.error('Error obteniendo productos:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

/**
 * @swagger
 * /api/productos/{id}:
 *   get:
 *     summary: Obtener un producto específico
 *     description: Recupera los detalles de un producto por su ID
 *     tags: [Productos]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: ID único del producto
 *         schema:
 *           type: integer
 *           example: 1
 *     responses:
 *       200:
 *         description: Producto encontrado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Producto'
 *       404:
 *         description: Producto no encontrado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Producto no encontrado"
 *       500:
 *         description: Error interno del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
app.get('/api/productos/:id', async (req, res) => {
  const start = Date.now();
  try {
    const [rows] = await db.execute('SELECT * FROM productos WHERE id = ?', [req.params.id]);
    const duration = (Date.now() - start) / 1000;
    dbQueryDuration.labels('select_product_by_id').observe(duration);
    productosConsultados.inc();
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Producto no encontrado' });
    }
    res.json(rows[0]);
  } catch (error) {
    console.error('Error obteniendo producto:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

/**
 * @swagger
 * /api/productos:
 *   post:
 *     summary: Crear un nuevo producto
 *     description: Crea un nuevo producto en la tienda
 *     tags: [Productos]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - nombre
 *               - precio
 *             properties:
 *               nombre:
 *                 type: string
 *                 example: "Laptop Dell XPS 15"
 *               descripcion:
 *                 type: string
 *                 example: "Laptop profesional de alto rendimiento"
 *               precio:
 *                 type: number
 *                 format: decimal
 *                 example: 1299.99
 *               stock:
 *                 type: integer
 *                 example: 15
 *               categoria:
 *                 type: string
 *                 example: "Computadoras"
 *               imagen_url:
 *                 type: string
 *                 example: "https://example.com/image.jpg"
 *     responses:
 *       201:
 *         description: Producto creado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: integer
 *                   example: 1
 *                 message:
 *                   type: string
 *                   example: "Producto creado exitosamente"
 *       400:
 *         description: Datos de entrada inválidos
 *       500:
 *         description: Error interno del servidor
 */
app.post('/api/productos', async (req, res) => {
  const start = Date.now();
  try {
    const { nombre, descripcion, precio, stock, categoria, imagen_url } = req.body;
    
    if (!nombre || !precio) {
      return res.status(400).json({ error: 'Nombre y precio son requeridos' });
    }
    
    const [result] = await db.execute(
      'INSERT INTO productos (nombre, descripcion, precio, stock, categoria, imagen_url) VALUES (?, ?, ?, ?, ?, ?)',
      [nombre, descripcion || null, precio, stock || 0, categoria || null, imagen_url || null]
    );
    
    const duration = (Date.now() - start) / 1000;
    dbQueryDuration.labels('create_product').observe(duration);
    
    res.status(201).json({ 
      id: result.insertId,
      message: 'Producto creado exitosamente' 
    });
  } catch (error) {
    console.error('Error creando producto:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

/**
 * @swagger
 * /api/pedidos:
 *   post:
 *     summary: Crear un nuevo pedido
 *     description: Crea un pedido con los productos especificados
 *     tags: [Pedidos]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - productos
 *               - total
 *               - cliente_email
 *               - cliente_nombre
 *             properties:
 *               productos:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     producto_id:
 *                       type: integer
 *                       example: 1
 *                     cantidad:
 *                       type: integer
 *                       example: 2
 *                     precio:
 *                       type: number
 *                       format: decimal
 *                       example: 19.99
 *               total:
 *                 type: number
 *                 format: decimal
 *                 example: 39.98
 *               cliente_email:
 *                 type: string
 *                 format: email
 *                 example: "cliente@ejemplo.com"
 *               cliente_nombre:
 *                 type: string
 *                 example: "Juan Pérez"
 *               cliente_telefono:
 *                 type: string
 *                 example: "+34 600 123 456"
 *               direccion_envio:
 *                 type: string
 *                 example: "Calle Ejemplo 123, Madrid"
 *           example:
 *             productos:
 *               - producto_id: 1
 *                 cantidad: 2
 *                 precio: 19.99
 *               - producto_id: 3
 *                 cantidad: 1
 *                 precio: 79.99
 *             total: 119.97
 *             cliente_email: "juan@ejemplo.com"
 *             cliente_nombre: "Juan Pérez"
 *             cliente_telefono: "+34 600 123 456"
 *             direccion_envio: "Calle Madrid 123, Madrid"
 *     responses:
 *       201:
 *         description: Pedido creado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Pedido creado exitosamente"
 *                 pedido_id:
 *                   type: integer
 *                   example: 1
 *       400:
 *         description: Datos de entrada inválidos
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Error interno del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
app.post('/api/pedidos', async (req, res) => {
  const start = Date.now();
  try {
    const { productos, total, cliente_email, cliente_nombre } = req.body;
    
    const [result] = await db.execute(
      'INSERT INTO pedidos (cliente_email, cliente_nombre, total, estado) VALUES (?, ?, ?, ?)',
      [cliente_email, cliente_nombre, total, 'pendiente']
    );
    
    const pedidoId = result.insertId;
    
    // Insertar items del pedido
    for (const item of productos) {
      await db.execute(
        'INSERT INTO pedido_items (pedido_id, producto_id, cantidad, precio) VALUES (?, ?, ?, ?)',
        [pedidoId, item.producto_id, item.cantidad, item.precio]
      );
    }
    
    const duration = (Date.now() - start) / 1000;
    dbQueryDuration.labels('create_order').observe(duration);
    pedidosCreados.inc();
    
    res.status(201).json({ 
      message: 'Pedido creado exitosamente', 
      pedido_id: pedidoId 
    });
  } catch (error) {
    console.error('Error creando pedido:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

/**
 * @swagger
 * /api-docs:
 *   get:
 *     summary: Documentación de la API
 *     description: Redirige a la documentación interactiva de Swagger
 *     tags: [General]
 *     responses:
 *       200:
 *         description: Documentación de la API disponible
 */

// Ruta de información de la API
/**
 * @swagger
 * /api:
 *   get:
 *     summary: Información de la API
 *     description: Proporciona información básica sobre la API y enlaces útiles
 *     tags: [General]
 *     responses:
 *       200:
 *         description: Información de la API
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 name:
 *                   type: string
 *                   example: "Tienda Online API"
 *                 version:
 *                   type: string
 *                   example: "1.0.0"
 *                 description:
 *                   type: string
 *                   example: "API REST para tienda online"
 *                 endpoints:
 *                   type: object
 *                   properties:
 *                     productos:
 *                       type: string
 *                       example: "/api/productos"
 *                     pedidos:
 *                       type: string
 *                       example: "/api/pedidos"
 *                     documentacion:
 *                       type: string
 *                       example: "/api-docs"
 */
app.get('/api', (req, res) => {
  res.json({
    name: 'Tienda Online API',
    version: '1.0.0',
    description: 'API REST para tienda online con Node.js, Express y MySQL',
    endpoints: {
      productos: '/api/productos',
      pedidos: '/api/pedidos',
      documentacion: '/api-docs'
    },
    swagger: `${req.protocol}://${req.get('host')}/api-docs`
  });
});

// Iniciar servidor
async function startServer() {
  try {
    await initDB();
    app.listen(PORT, () => {
      console.log(`Servidor corriendo en puerto ${PORT}`);
    });
  } catch (error) {
    console.error('Error crítico al iniciar el servidor:', error);
    process.exit(1);
  }
}

startServer();
