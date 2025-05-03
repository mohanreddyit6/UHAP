<%@ page import="java.sql.*, org.json.simple.JSONObject, org.json.simple.JSONArray" %>
<%@ page contentType="application/json" %>
<%
    JSONArray labels = new JSONArray();  // To hold month names
    JSONArray values = new JSONArray();  // To hold claim totals
    JSONObject result = new JSONObject();

    try {
        String yearParam = request.getParameter("year");
        String url = application.getInitParameter("dbUrl");
        String user = application.getInitParameter("dbUser");
        String password = application.getInitParameter("dbPassword");

        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(url, user, password);

        String query = "SELECT MONTH(TODATE) AS month_number, DATE_FORMAT(TODATE, '%M') AS month_name, SUM(amount) AS total_amount FROM claims_transactions";
        if (yearParam != null && !yearParam.isEmpty()) {
            query += " WHERE YEAR(TODATE) = ?";
        }
        query += " GROUP BY month_number, month_name ORDER BY month_number";

        PreparedStatement ps = con.prepareStatement(query);
        if (yearParam != null && !yearParam.isEmpty()) {
            ps.setInt(1, Integer.parseInt(yearParam));
        }

        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            labels.add(rs.getString("month_name"));
            values.add(rs.getDouble("total_amount"));
        }

        result.put("labels", labels);
        result.put("values", values);
        out.print(result.toJSONString());

        rs.close();
        ps.close();
        con.close();
    } catch (Exception e) {
        JSONObject error = new JSONObject();
        error.put("error", e.getMessage());
        out.print(error.toJSONString());
    }
%>
