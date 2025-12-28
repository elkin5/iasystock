package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.stats

import com.co.kinsoft.api.iasy_stock_api.domain.gateway.StatsRepository
import com.co.kinsoft.api.iasy_stock_api.domain.model.stats.SalesByDateStat
import com.co.kinsoft.api.iasy_stock_api.domain.model.stats.TopProductStat
import org.springframework.r2dbc.core.DatabaseClient
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import java.math.BigDecimal
import java.time.LocalDate

@Repository
class StatsRepositoryAdapter(
    private val client: DatabaseClient
) : StatsRepository {

    override fun getSalesByDate(from: LocalDate?, to: LocalDate?): Flux<SalesByDateStat> {
        val sql = StringBuilder(
            """
            SELECT COALESCE(date(sale_date), date(created_at)) AS sale_day,
                   COUNT(*) AS total_sales,
                   COALESCE(SUM(total_amount), 0) AS total_amount
            FROM schmain.sale
            WHERE 1=1
            """.trimIndent()
        )

        val bindings = mutableMapOf<String, Any>()

        from?.let {
            sql.append(" AND COALESCE(date(sale_date), date(created_at)) >= :fromDate")
            bindings["fromDate"] = it
        }
        to?.let {
            sql.append(" AND COALESCE(date(sale_date), date(created_at)) <= :toDate")
            bindings["toDate"] = it
        }

        sql.append(" GROUP BY sale_day ORDER BY sale_day ASC")

        var spec = client.sql(sql.toString())
        bindings.forEach { (k, v) -> spec = spec.bind(k, v) }

        return spec.map { row ->
            SalesByDateStat(
                date = row.get("sale_day", LocalDate::class.java) ?: LocalDate.now(),
                totalSales = row.get("total_sales", java.lang.Long::class.java)?.toLong() ?: 0L,
                totalAmount = row.get("total_amount", BigDecimal::class.java) ?: BigDecimal.ZERO
            )
        }.all()
    }

    override fun getTopProducts(limit: Int): Flux<TopProductStat> {
        val sql = """
            SELECT si.product_id      AS product_id,
                   COALESCE(p.name, 'Producto') AS product_name,
                   SUM(si.quantity)   AS total_quantity,
                   COALESCE(SUM(si.total_price), 0) AS total_amount
            FROM schmain.saleitem si
            LEFT JOIN schmain.product p ON p.product_id = si.product_id
            GROUP BY si.product_id, p.name
            ORDER BY total_quantity DESC
            LIMIT :limit
        """.trimIndent()

        return client.sql(sql)
            .bind("limit", limit)
            .map { row ->
                TopProductStat(
                    productId = row.get("product_id", java.lang.Long::class.java)?.toLong() ?: 0L,
                    productName = row.get("product_name", String::class.java) ?: "Producto",
                    totalQuantity = row.get("total_quantity", java.lang.Long::class.java)?.toLong() ?: 0L,
                    totalAmount = row.get("total_amount", BigDecimal::class.java) ?: BigDecimal.ZERO
                )
            }
            .all()
    }
}
