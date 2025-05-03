<%@ page import="java.sql.*, java.util.ArrayList" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Resource Utilization</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
</head>
<body>
<div class="container mt-4">
    <h3 class="mb-4">Resource Utilization</h3>
    <div class="row text-center mb-4">
        <div class="col-md-6">
            <div class="card bg-success text-white">
                <div class="card-body">
                    <h5>Total Supplies Used</h5>
                    <h4 id="totalUsed">Loading...</h4>
                </div>
            </div>
        </div>
        <div class="col-md-6">
            <div class="card bg-danger text-white">
                <div class="card-body">
                    <h5>Shortages Detected</h5>
                    <h4 id="shortages">Loading...</h4>
                </div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-body">
            <div class="d-flex justify-content-between">
                <h5>Supply Usage Over Time (by Year)</h5>
                <div class="d-flex gap-2">
                    <select id="categorySelect" class="form-select">
                        <option value="all">All</option>
                        <% 
                            String url = application.getInitParameter("dbUrl");
                            String user = application.getInitParameter("dbUser");
                            String password = application.getInitParameter("dbPassword");
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            Connection con = DriverManager.getConnection(url, user, password);
                            Statement stmt = con.createStatement();
                            ResultSet rs = stmt.executeQuery("SELECT DISTINCT Description FROM supplies");
                            while (rs.next()) {
                                String desc = rs.getString("Description");
                        %>
                        <option value="<%=desc%>"><%=desc%></option>
                        <% } rs.close(); stmt.close(); con.close(); %>
                    </select>
                    <button class="btn btn-outline-secondary" id="exportBtn">Save Report</button>
                </div>
            </div>
            <canvas id="supplyChart" height="100"></canvas>
        </div>
    </div>
</div>

<script>
    function fetchSupplyData(description = 'all') {
        $.ajax({
            url: "get_resource_data.jsp",
            method: "GET",
            data: { description: description },
            dataType: "json",
            success: function (data) {
                if (data.error) {
                    alert("Error: " + data.error);
                    return;
                }
                updateChart(data.labels, data.values, data.shortages);
                $('#totalUsed').text(data.totalUsed);
                $('#shortages').text(data.shortagesTotal);
            }
        });
    }

    function updateChart(labels, values, shortages) {
        const ctx = document.getElementById("supplyChart").getContext("2d");
        if (window.supplyChart && typeof window.supplyChart.destroy === "function") {
            window.supplyChart.destroy();
        }
        window.supplyChart = new Chart(ctx, {
            type: "bar",
            data: {
                labels: labels,
                datasets: [
                    {
                        label: "Supplies Used",
                        data: values,
                        backgroundColor: "rgba(0, 123, 255, 0.6)"
                    },
                    {
                        label: "Shortages Detected",
                        data: shortages,
                        backgroundColor: "rgba(220, 53, 69, 0.6)"
                    }
                ]
            },
            options: {
                responsive: true,
                plugins: {
                    tooltip: { enabled: true },
                    legend: { display: true },
                    title: {
                        display: true,
                        text: "Yearly Supply Usage and Shortages (after 2010)"
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    $(document).ready(function () {
        fetchSupplyData();
        $('#categorySelect').change(function () {
            fetchSupplyData($(this).val());
        });

        $('#exportBtn').click(function () {
            html2canvas(document.querySelector("#supplyChart")).then(canvas => {
                const imgData = canvas.toDataURL("image/png");
                const pdf = new jspdf.jsPDF();
                pdf.addImage(imgData, 'PNG', 10, 10, 180, 100);
                pdf.save("Resource_Data.pdf");
            });
        });
    });
</script>
<br>
<h6>Note: </h6>
 <h6 style="color: black">* Shortages are calculating based on the assumption value of 5 </h6>
</body>
</html>
