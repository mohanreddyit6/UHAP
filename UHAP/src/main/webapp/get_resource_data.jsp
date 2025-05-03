<%@ page contentType="application/json" %>
<%@ page import="java.sql.*, java.util.*, org.json.*" %>

<%
    String descriptionFilter = request.getParameter("description");
    if (descriptionFilter == null || descriptionFilter.equals("all")) {
        descriptionFilter = "";
    }

    String url = application.getInitParameter("dbUrl");
    String user = application.getInitParameter("dbUser");
    String password = application.getInitParameter("dbPassword");

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = DriverManager.getConnection(url, user, password);

    String query = "SELECT * FROM supplies";
    if (!descriptionFilter.isEmpty()) {
        query += " WHERE Description = ?";
    }

    PreparedStatement stmt = con.prepareStatement(query);
    if (!descriptionFilter.isEmpty()) {
        stmt.setString(1, descriptionFilter);
    }

    ResultSet rs = stmt.executeQuery();

    Map<Integer, Integer> yearlyUsage = new HashMap<>();
    Map<Integer, Integer> yearlyShortage = new HashMap<>();
    int totalUsed = 0;
    int shortagesTotal = 0;

    while (rs.next()) {
        String desc = rs.getString("Description");
        java.sql.Date date = rs.getDate("Date");
        int year = date.toLocalDate().getYear();
        int qty = rs.getInt("Quantity");

        if (qty < 0) continue;
        if (!descriptionFilter.isEmpty() && !desc.equals(descriptionFilter)) continue;

        yearlyUsage.put(year, yearlyUsage.getOrDefault(year, 0) + qty);
    }

    rs.close();
    stmt.close();
    con.close();

    // Step 2: Predict 2026 using 5-year average (excluding 2025 if needed)
    List<Integer> sortedYears = new ArrayList<>(yearlyUsage.keySet());
    Collections.sort(sortedYears);

    int predicted2026 = 1000; // default
    List<Integer> validYears = new ArrayList<>();
    for (int year : sortedYears) {
        if (year <= 2025) {
            validYears.add(year);
        }
    }

    List<Integer> lastFiveYears = validYears.subList(Math.max(validYears.size() - 5, 0), validYears.size());
    int sum = 0;
    for (int y : lastFiveYears) {
        sum += yearlyUsage.get(y);
    }
    if (!lastFiveYears.isEmpty()) {
        predicted2026 = sum / lastFiveYears.size();
    }

    yearlyUsage.put(2026, predicted2026);

    // Step 3: Apply custom supply limit logic to all years
    for (Map.Entry<Integer, Integer> entry : yearlyUsage.entrySet()) {
        int year = entry.getKey();
        int used = entry.getValue();

        int customLimit;
        if (used > 5000) {
            customLimit = 3000;
        } else if (used <= 5000 && used > 4000) {
            customLimit = 2500;
        } else if (used <= 4000 && used > 3000) {
            customLimit = 1500;
        } else if (used <= 3000 && used > 2000) {
            customLimit = 900;
        } else if (used <= 2000 && used > 1000) {
            customLimit = 700;
        } else if (used <= 1000 && used > 300) {
            customLimit = 500;
        } else if (used <= 300 && used > 100) {
            customLimit = 200;
        } else {
            customLimit = 50;
        }

        int shortage = Math.max(0, used - customLimit);
        yearlyShortage.put(year, shortage);
        totalUsed += used;
        shortagesTotal += shortage;
    }

    // Step 4: Prepare JSON output
    JSONArray labels = new JSONArray();
    JSONArray values = new JSONArray();
    JSONArray shortages = new JSONArray();
    JSONArray predictedFlags = new JSONArray();

    List<Integer> allYears = new ArrayList<>(yearlyUsage.keySet());
    Collections.sort(allYears);
    for (int year : allYears) {
        if (year >= 2010) {
            if (year == 2026) {
                labels.put("2026 (Predicted)");
                predictedFlags.put(true);
            } else {
                labels.put(String.valueOf(year));
                predictedFlags.put(false);
            }

            values.put(yearlyUsage.get(year));
            shortages.put(yearlyShortage.getOrDefault(year, 0));
        }
    }

    JSONObject result = new JSONObject();
    result.put("labels", labels);
    result.put("values", values);
    result.put("shortages", shortages);
    result.put("predicted", predictedFlags);
    result.put("totalUsed", totalUsed);
    result.put("shortagesTotal", shortagesTotal);

    out.print(result.toString());
%>
