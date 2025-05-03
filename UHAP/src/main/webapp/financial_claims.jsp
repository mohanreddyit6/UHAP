<%@ page import="java.sql.*, org.json.simple.JSONArray, org.json.simple.JSONObject"%>
<%@ page contentType="text/html;charset=UTF-8" language="java"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Financial Claims Over Time</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container mt-4">
        <h3 class="mb-4">Financial Claims Processed Over Time</h3>

        <div class="mb-3">
            <label for="yearFilter" class="form-label">Select Year:</label>
            <select id="yearFilter" class="form-select" style="width: 200px;">
                <option value="">All Years</option>
                <option value="2021">2021</option>
                <option value="2022">2022</option>
                <option value="2023">2023</option>
                <option value="2024">2024</option>
                <option value="2025">2025</option>
            </select>
        </div>

        <div class="card">
            <div class="card-body">
                <canvas id="claimsChart" height="100"></canvas>
            </div>
        </div>
    </div>

    <script>
        function fetchClaimsData(year = '') {
            $.ajax({
                url: "get_claims_data.jsp",
                method: "GET",
                data: { year: year },
                dataType: "json",
                success: function(data) {
                    if (data.error) {
                        alert("Error: " + data.error);
                        return;
                    }
                    updateChart(data.labels, data.values);
                },
                error: function(xhr, status, error) {
                    console.error("AJAX Error:", status, error);
                }
            });
        }

        function updateChart(labels, values) {
            const ctx = document.getElementById("claimsChart").getContext("2d");

            if (window.claimsChart && typeof window.claimsChart.destroy === "function") {
                window.claimsChart.destroy();
            }

            window.claimsChart = new Chart(ctx, {
                type: "line",
                data: {
                    labels: labels,
                    datasets: [{
                        label: "Claim Amounts",
                        data: values,
                        borderColor: "blue",
                        backgroundColor: "rgba(0, 255, 0, 0.2)",
                        fill: true,
                        tension: 0.4,
                        pointHoverRadius: 6,
                        pointHoverBackgroundColor: "red"
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        tooltip: { enabled: true },
                        legend: { display: true },
                        title: {
                            display: true,
                            text: "Monthly Claims Processed"
                        }
                    }
                }
            });
        }

        $(document).ready(function() {
            fetchClaimsData(); // Load all years initially

            $('#yearFilter').on('change', function () {
                const selectedYear = $(this).val();
                fetchClaimsData(selectedYear);
            });
        });
    </script>
</body>
</html>