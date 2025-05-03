<%@ page import="java.sql.*, org.json.simple.JSONObject, org.json.simple.JSONArray" %>
<%@ page contentType="application/json" %>
<%
JSONArray labels = new JSONArray();
JSONArray values = new JSONArray();
JSONObject result = new JSONObject();

try {
    String category = request.getParameter("category");
    String groupBy, labelQuery;
    String query;

    // DB connection
    String url = application.getInitParameter("dbUrl");
    String user = application.getInitParameter("dbUser");
    String password = application.getInitParameter("dbPassword");

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = DriverManager.getConnection(url, user, password);
    Statement stmt = con.createStatement();
    stmt.execute("SET sql_mode = ''"); // Disable ONLY_FULL_GROUP_BY

    if ("all".equalsIgnoreCase(category)) {
        query = "SELECT MONTHNAME(START) AS label, COUNT(*) AS visits FROM encounters GROUP BY MONTH(START) ORDER BY MONTH(START)";
    } else {
        query = "SELECT " + category + " AS label, COUNT(*) AS visits FROM patients JOIN encounters ON patients.Id = encounters.PATIENT GROUP BY " + category + " ORDER BY visits DESC";
    }

    ResultSet rs = stmt.executeQuery(query);
    while (rs.next()) {
        labels.add(rs.getString("label"));
        values.add(rs.getInt("visits"));
    }

    result.put("labels", labels);
    result.put("values", values);
    out.print(result.toJSONString());

    rs.close();
    stmt.close();
    con.close();
} catch (Exception e) {
    JSONObject error = new JSONObject();
    error.put("error", e.getMessage());
    out.print(error.toJSONString());
}
%>
