-- Active: 1729102093806@@127.0.0.1@3306@mysql_database
SELECT anio, SUM(monto_total_adjudicado) AS "monto_total_año" FROM proyectos_ciencia_tecnologia.detalle_proyectos
GROUP BY anio
ORDER BY anio;