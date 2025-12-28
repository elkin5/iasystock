package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat

/**
 * Proveedor de ejemplos de consultas SQL para entrenar al modelo LLM
 * Estos ejemplos ayudan a OpenAI a entender cómo construir consultas SQL correctas
 */
class SQLExamplesProvider {

    companion object {
        fun getSQLExamples(): String {
            return """
        EJEMPLOS DE CONSULTAS SQL EXITOSAS:

        1. Consulta: "¿Cuántos productos tengo en stock?"
           SQL:
           SELECT
               COUNT(*) as total_productos,
               SUM(stock_quantity) as total_stock,
               COUNT(CASE WHEN stock_quantity > 0 THEN 1 END) as productos_con_stock
           FROM schmain.product

        2. Consulta: "¿Cuáles son mis productos más vendidos en los últimos 30 días?"
           SQL:
           SELECT
               p.product_id,
               p.name as producto,
               SUM(si.quantity) as total_vendido,
               SUM(si.total_price) as ingresos_totales,
               c.name as categoria
           FROM schmain.product p
           INNER JOIN schmain.saleitem si ON p.product_id = si.product_id
           INNER JOIN schmain.sale s ON si.sale_id = s.sale_id
           LEFT JOIN schmain.category c ON p.category_id = c.category_id
           WHERE s.sale_date >= CURRENT_DATE - INTERVAL '30 days'
           GROUP BY p.product_id, p.name, c.name
           ORDER BY total_vendido DESC
           LIMIT 10

        3. Consulta: "¿Qué productos están por vencer en los próximos 7 días?"
           SQL:
           SELECT
               p.product_id,
               p.name,
               p.expiration_date,
               p.stock_quantity,
               c.name as categoria,
               (p.expiration_date - CURRENT_DATE) as dias_restantes
           FROM schmain.product p
           LEFT JOIN schmain.category c ON p.category_id = c.category_id
           WHERE p.expiration_date IS NOT NULL
           AND p.expiration_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
           ORDER BY p.expiration_date ASC

        4. Consulta: "¿Qué productos tienen stock bajo o están agotados?"
           SQL:
           SELECT
               p.product_id,
               p.name,
               p.stock_quantity,
               p.stock_minimum,
               c.name as categoria,
               CASE
                   WHEN p.stock_quantity = 0 THEN 'Agotado'
                   WHEN p.stock_quantity <= p.stock_minimum THEN 'Stock bajo'
                   ELSE 'Stock normal'
               END as estado_stock
           FROM schmain.product p
           LEFT JOIN schmain.category c ON p.category_id = c.category_id
           WHERE p.stock_quantity <= p.stock_minimum
           ORDER BY p.stock_quantity ASC

        5. Consulta: "¿Cuál es el total de ventas por método de pago este mes?"
           SQL:
           SELECT
               s.pay_method as metodo_pago,
               COUNT(*) as numero_ventas,
               SUM(s.total_amount) as total_ingresos,
               AVG(s.total_amount) as promedio_venta
           FROM schmain.sale s
           WHERE s.sale_date >= DATE_TRUNC('month', CURRENT_DATE)
           GROUP BY s.pay_method
           ORDER BY total_ingresos DESC

        6. Consulta: "¿Cuáles son las ventas recientes?"
           SQL:
           SELECT
               s.sale_id,
               s.sale_date,
               s.total_amount,
               s.pay_method,
               p.name as person_name,
               u.username as vendedor
           FROM schmain.sale s
           LEFT JOIN schmain.person p ON s.person_id = p.person_id
           LEFT JOIN schmain."user" u ON s.user_id = u.id
           ORDER BY s.sale_date DESC
           LIMIT 10

        7. Consulta: "¿Cuál es el valor total de mi inventario por categoría?"
           SQL:
           SELECT
               c.category_id,
               c.name as categoria,
               COUNT(p.product_id) as total_productos,
               SUM(p.stock_quantity) as total_unidades,
               SUM(p.stock_quantity * p.price) as valor_total_inventario
           FROM schmain.category c
           LEFT JOIN schmain.product p ON c.category_id = p.category_id
           GROUP BY c.category_id, c.name
           ORDER BY valor_total_inventario DESC

        8. Consulta: "¿Qué productos nunca se han vendido?"
           SQL:
           SELECT
               p.product_id,
               p.name,
               p.price,
               p.stock_quantity,
               c.name as categoria,
               p.created_at as fecha_creacion
           FROM schmain.product p
           LEFT JOIN schmain.saleitem si ON p.product_id = si.product_id
           LEFT JOIN schmain.category c ON p.category_id = c.category_id
           WHERE si.product_id IS NULL
           ORDER BY p.created_at DESC

        9. Consulta: "¿Cuáles son los mejores clientes del último trimestre?"
           SQL:
           SELECT
               p.person_id,
               p.name as cliente,
               p.email,
               p.cell_phone,
               COUNT(s.sale_id) as total_compras,
               SUM(s.total_amount) as total_gastado,
               AVG(s.total_amount) as promedio_compra
           FROM schmain.person p
           INNER JOIN schmain.sale s ON p.person_id = s.person_id
           WHERE s.sale_date >= CURRENT_DATE - INTERVAL '3 months'
           AND p.type = 'Customer'
           GROUP BY p.person_id, p.name, p.email, p.cell_phone
           ORDER BY total_gastado DESC
           LIMIT 10

        10. Consulta: "¿Cuántos productos hay por categoría?"
            SQL:
            SELECT
                c.category_id,
                c.name as categoria,
                COUNT(p.product_id) as total_productos,
                COALESCE(SUM(p.stock_quantity), 0) as total_stock
            FROM schmain.category c
            LEFT JOIN schmain.product p ON c.category_id = p.category_id
            GROUP BY c.category_id, c.name
            ORDER BY total_productos DESC

        11. Consulta: "¿Cuál fue el total de ventas de ayer?"
            SQL:
            SELECT
                COUNT(*) as total_ventas,
                SUM(total_amount) as ingresos_totales,
                AVG(total_amount) as promedio_venta,
                MIN(total_amount) as venta_minima,
                MAX(total_amount) as venta_maxima
            FROM schmain.sale
            WHERE sale_date = CURRENT_DATE - INTERVAL '1 day'

        12. Consulta: "Dame información detallada del producto 5"
            SQL:
            SELECT
                p.product_id,
                p.name,
                p.description,
                p.price,
                p.stock_quantity,
                p.stock_minimum,
                p.expiration_date,
                p.created_at,
                c.name as categoria,
                c.description as descripcion_categoria,
                CASE
                    WHEN p.stock_quantity = 0 THEN 'Sin stock'
                    WHEN p.stock_quantity <= p.stock_minimum THEN 'Stock bajo'
                    WHEN p.stock_quantity > p.stock_minimum * 3 THEN 'Stock alto'
                    ELSE 'Stock normal'
                END as estado_stock
            FROM schmain.product p
            LEFT JOIN schmain.category c ON p.category_id = c.category_id
            WHERE p.product_id = 5

        13. Consulta: "¿Qué productos se vendieron esta semana?"
            SQL:
            SELECT
                p.product_id,
                p.name,
                SUM(si.quantity) as unidades_vendidas,
                SUM(si.total_price) as ingresos_generados,
                COUNT(DISTINCT s.sale_id) as numero_transacciones
            FROM schmain.product p
            INNER JOIN schmain.saleitem si ON p.product_id = si.product_id
            INNER JOIN schmain.sale s ON si.sale_id = s.sale_id
            WHERE s.sale_date >= DATE_TRUNC('week', CURRENT_DATE)
            GROUP BY p.product_id, p.name
            ORDER BY unidades_vendidas DESC

        14. Consulta: "¿Cuántas entradas de stock hubo este mes por proveedor?"
            SQL:
            SELECT
                p.person_id,
                p.name as proveedor,
                COUNT(st.stock_id) as total_entradas,
                SUM(st.quantity) as total_unidades,
                SUM(st.quantity * st.entry_price) as valor_total_compras
            FROM schmain.person p
            INNER JOIN schmain.stock st ON p.person_id = st.person_id
            WHERE st.entry_date >= DATE_TRUNC('month', CURRENT_DATE)
            AND p.type = 'Supplier'
            GROUP BY p.person_id, p.name
            ORDER BY valor_total_compras DESC

        15. Consulta: "¿Qué productos están en el almacén principal?"
            SQL:
            SELECT
                p.product_id,
                p.name as producto,
                st.quantity as cantidad_entrada,
                w.name as almacen,
                w.location as ubicacion,
                st.entry_date
            FROM schmain.product p
            INNER JOIN schmain.stock st ON p.product_id = st.product_id
            INNER JOIN schmain.warehouse w ON st.warehouse_id = w.warehouse_id
            WHERE w.warehouse_id = 1
            ORDER BY st.entry_date DESC
        
        16. Consulta: "¿Cuál es el precio de venta de una 'manzana'?"
        SELECT s.sale_price
        FROM schmain.product p
        INNER JOIN schmain.stock s ON p.product_id = s.product_id
        WHERE p.name ILIKE 'manzana%'
        ORDER BY s.stock_id DESC
        LIMIT 1;
        
        17. Consulta: "¿Cuál es el precio de compra de una 'manzana'?"
        SELECT s.entry_price
        FROM schmain.product p
        INNER JOIN schmain.stock s ON p.product_id = s.product_id
        WHERE p.name ILIKE 'manzana%'
        ORDER BY s.stock_id DESC;

        18. Consulta: "¿Puedes hacer un listado de las ventas pendientes?"
            (O variaciones: "ventas en estado pendiente", "qué ventas están pendientes", etc.)
            SQL:
            SELECT
                s.sale_id,
                s.sale_date,
                s.total_amount,
                s.pay_method,
                s.state as estado,
                p.name as person_name,
                p.email,
                p.cell_phone,
                u.username as vendedor
            FROM schmain.sale s
            LEFT JOIN schmain.person p ON s.person_id = p.person_id
            LEFT JOIN schmain."user" u ON s.user_id = u.id
            WHERE s.state = 'Pendiente'
            ORDER BY s.sale_date DESC

        19. Consulta: "¿Cuántas ventas hay por cada estado?"
            SQL:
            SELECT
                s.state as estado,
                COUNT(*) as total_ventas,
                SUM(s.total_amount) as monto_total,
                AVG(s.total_amount) as promedio_venta,
                MIN(s.sale_date) as venta_mas_antigua,
                MAX(s.sale_date) as venta_mas_reciente
            FROM schmain.sale s
            GROUP BY s.state
            ORDER BY total_ventas DESC

        REGLAS IMPORTANTES PARA CONSTRUIR CONSULTAS SQL:

        1. SIEMPRE usar el schema 'schmain' antes del nombre de la tabla: schmain.product

        2. Para JOINs:
           - Usar INNER JOIN cuando ambas tablas deben tener datos relacionados
           - Usar LEFT JOIN cuando la tabla derecha puede no tener datos
           - Siempre especificar la condición ON con las columnas de las FK

        3. Para agregaciones (COUNT, SUM, AVG):
           - Usar COALESCE() para manejar NULL: COALESCE(SUM(price), 0)
           - Incluir todas las columnas no agregadas en GROUP BY
           - Usar DISTINCT cuando sea necesario evitar duplicados

        4. Para fechas:
           - Fecha actual: CURRENT_DATE
           - Timestamp actual: CURRENT_TIMESTAMP
           - Restar días: CURRENT_DATE - INTERVAL '7 days'
           - Sumar días: CURRENT_DATE + INTERVAL '30 days'
           - Inicio de mes: DATE_TRUNC('month', CURRENT_DATE)
           - Inicio de semana: DATE_TRUNC('week', CURRENT_DATE)

        5. Para filtros con texto:
           - Búsqueda insensible a mayúsculas: WHERE name ILIKE '%texto%'
           - Búsqueda exacta: WHERE name = 'texto'

        6. Para ordenamiento:
           - Descendente (mayor a menor): ORDER BY columna DESC
           - Ascendente (menor a mayor): ORDER BY columna ASC
           - Múltiples columnas: ORDER BY col1 DESC, col2 ASC

        7. Para limitar resultados:
           - Usar LIMIT N para los primeros N resultados
           - Combinar con ORDER BY para obtener los "top N"

        8. Para condiciones complejas:
           - Usar CASE WHEN para lógica condicional
           - Usar IN para múltiples valores: WHERE type IN ('Customer', 'Supplier')
           - Usar BETWEEN para rangos: WHERE price BETWEEN 100 AND 500
           
        9. Para preguntas con valores string por ejemplo el nombre de un producto (name):
              - Siempre encerrar los valores string entre comillas simples: 'manzana'
              - Siempre usar ILIKE para búsquedas insensibles a mayúsculas/minúsculas
              - siempre usar el símbolo % para búsquedas parciales: ILIKE 'manzana%'

        10. Para filtrar ventas por estado:
              - La tabla 'sale' tiene la columna 'state' (NO 'status')
              - Valores posibles: 'Pendiente', 'Completada', 'Cancelada'
              - Usar comparación exacta: WHERE state = 'Pendiente'
              - Para múltiples estados: WHERE state IN ('Pendiente', 'Cancelada')
        """.trimIndent()
        }
    }
}