<%@ page import="java.util.*, java.sql.*, org.json.JSONObject, org.json.JSONArray" %>
<%@ page contentType="text/html;charset=UTF-8" language="java"%>

<%
    // Database connection setup
    String url = application.getInitParameter("dbUrl");
    String user = application.getInitParameter("dbUser");
    String password = application.getInitParameter("dbPassword");

    // Create JSON objects to store chart data
    JSONObject activityData = new JSONObject();
    JSONArray topProvidersData = new JSONArray();
    JSONArray providerTableData = new JSONArray();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(url, user, password);

        // Query 1: Get activity distribution data
        String activityQuery = "SELECT SUM(p.encounters) AS total_encounters, "
                             + "SUM(p.procedures) AS total_procedures, "
                             + "COUNT(c.id) AS total_claims "
                             + "FROM providers p "
                             + "LEFT JOIN claims c ON p.id = c.providerid";

        Statement activityStmt = con.createStatement();
        ResultSet activityRs = activityStmt.executeQuery(activityQuery);

        if (activityRs.next()) {
            activityData.put("encounters", activityRs.getInt("total_encounters"));
            activityData.put("procedures", activityRs.getInt("total_procedures"));
            activityData.put("claims", activityRs.getInt("total_claims"));
        }

        // Query 2: Get top providers data
        String topProvidersQuery = "SELECT p.name, p.encounters, p.procedures "
                                 + "FROM providers p ORDER BY p.encounters DESC LIMIT 5";

        Statement topProvidersStmt = con.createStatement();
        ResultSet topProvidersRs = topProvidersStmt.executeQuery(topProvidersQuery);

        while (topProvidersRs.next()) {
            JSONObject provider = new JSONObject();
            provider.put("name", topProvidersRs.getString("name"));
            provider.put("encounters", topProvidersRs.getInt("encounters"));
            provider.put("procedures", topProvidersRs.getInt("procedures"));
            topProvidersData.put(provider);
        }

        // Query 3: Get detailed provider data for table
        // Utilize max(encounters) to calculate utilization out of 100% per provider
        String tableQuery = "SELECT p.id, p.name, p.speciality, p.encounters, p.procedures, "
                          + "COUNT(c.id) as claims_count, "
                          + "ROUND((p.encounters / (SELECT MAX(encounters) FROM providers)) * 100, 2) as utilization "
                          + "FROM providers p "
                          + "LEFT JOIN claims c ON p.id = c.providerid "
                          + "GROUP BY p.id, p.name, p.speciality, p.encounters, p.procedures "
                          + "ORDER BY p.encounters DESC LIMIT 15";

        Statement tableStmt = con.createStatement();
        ResultSet tableRs = tableStmt.executeQuery(tableQuery);

        while (tableRs.next()) {
            JSONObject row = new JSONObject();
            row.put("id", tableRs.getString("id"));
            row.put("name", tableRs.getString("name"));
            row.put("speciality", tableRs.getString("speciality"));
            row.put("encounters", tableRs.getInt("encounters"));
            row.put("procedures", tableRs.getInt("procedures"));
            row.put("claims_count", tableRs.getInt("claims_count"));
            row.put("utilization", tableRs.getDouble("utilization"));
            providerTableData.put(row);
        }

        // Query 4: Get summary metrics
        String summaryQuery = "SELECT "
                            + "COUNT(DISTINCT p.id) AS total_providers, "
                            + "SUM(p.encounters) AS total_encounters, "
                            + "ROUND(AVG(p.encounters / (SELECT AVG(encounters) FROM providers)) * 100, 2) AS avg_utilization "
                            + "FROM providers p";

        Statement summaryStmt = con.createStatement();
        ResultSet summaryRs = summaryStmt.executeQuery(summaryQuery);

        if (summaryRs.next()) {
            activityData.put("total_providers", summaryRs.getInt("total_providers"));
            activityData.put("total_encounters", summaryRs.getInt("total_encounters"));
            activityData.put("avg_utilization", summaryRs.getDouble("avg_utilization"));
        }

        con.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Provider Activity</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        /* Custom styles */
        .card {
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
            border: none;
        }

        .card-header {
            background-color: #00b894;
            color: white;
            border-radius: 10px 10px 0 0 !important;
            font-weight: 600;
        }

        .filter-section {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }

        .chart-container {
            position: relative;
            height: 400px;
            margin-bottom: 20px;
        }

        .table-container {
            overflow-x: auto;
        }

        .badge-encounters {
            background-color: #3498db;
        }

        .badge-procedures {
            background-color: #e74c3c;
        }

        .badge-claims {
            background-color: #2ecc71;
        }

        .utilization-high {
            color: #27ae60;
            font-weight: bold;
        }

        .utilization-medium {
            color: #f39c12;
            font-weight: bold;
        }

        .utilization-low {
            color: #e74c3c;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container-fluid">
        <div class="row mb-4">
            <div class="col">
                <h2 class="mb-0">Provider Activity</h2>
                <p class="text-muted">Overview of provider engagements and performance metrics</p>
            </div>
            <div class="col-auto">
                <button class="btn btn-outline-secondary" onclick="exportToPDF()">
                    <i class="fas fa-file-pdf"></i> Export PDF
                </button>
            </div>
        </div>

        <!-- Filter Section -->
        <div class="filter-section">
            <div class="row">
                <div class="col-md-3">
                    <label for="timePeriod" class="form-label">Time Period</label>
                    <select class="form-select" id="timePeriod">
                        <option value="30">Last 30 Days</option>
                        <option value="90">Last 90 Days</option>
                        <option value="365" selected>Last 12 Months</option>
                        <option value="custom">Custom Range</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label for="department" class="form-label">Department</label>
                    <select class="form-select" id="department">
                        <option value="all" selected>All Departments</option>
                        <option value="cardiology">Cardiology</option>
                        <option value="neurology">Neurology</option>
                        <option value="orthopedics">Orthopedics</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label for="providerType" class="form-label">Provider Type</label>
                    <select class="form-select" id="providerType">
                        <option value="all" selected>All Providers</option>
                        <option value="physician">Physicians</option>
                        <option value="nurse">Nurse Practitioners</option>
                        <option value="specialist">Specialists</option>
                    </select>
                </div>
                <div class="col-md-3 d-flex align-items-end">
                    <button class="btn btn-primary w-100" onclick="loadProviderData()">
                        <i class="fas fa-filter"></i> Apply Filters
                    </button>
                </div>
            </div>
        </div>

        <!-- Summary Cards -->
        <div class="row">
            <div class="col-md-4">
                <div class="card">
                    <div class="card-header">Total Providers</div>
                    <div class="card-body">
                        <h1 class="card-title"><%= activityData.has("total_providers") ? activityData.getInt("total_providers") : "N/A" %></h1>
                        <p class="card-text text-muted">Active providers in selected period</p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card">
                    <div class="card-header">Total Encounters</div>
                    <div class="card-body">
                        <h1 class="card-title"><%= activityData.has("total_encounters") ? activityData.getInt("total_encounters") : "N/A" %></h1>
                        <p class="card-text text-muted">Patient encounters recorded</p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card">
                    <div class="card-header">Avg. Utilization</div>
                    <div class="card-body">
                        <h1 class="card-title"><%= activityData.has("avg_utilization") ? activityData.getDouble("avg_utilization") + "%" : "N/A" %></h1>
                        <p class="card-text text-muted">Of provider capacity</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Charts Row -->
        <div class="row mt-4">
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header">Activity Distribution</div>
                    <div class="card-body">
                        <div class="chart-container">
                            <canvas id="activityChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header">Top Providers</div>
                    <div class="card-body">
                        <div class="chart-container">
                            <canvas id="topProvidersChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Provider Table -->
        <div class="row mt-4">
            <div class="col">
                <div class="card">
                    <div class="card-header">Provider Activity Details</div>
                    <div class="card-body table-container">
                        <table class="table table-striped table-hover">
                            <thead>
                                <tr>
                                    <th>Provider</th>
                                    <th>Specialty</th>
                                    <th>Encounters</th>
                                    <th>Procedures</th>
                                    <th>Claims</th>
                                    <th>Utilization</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% 
                                for (int i = 0; i < providerTableData.length(); i++) {
                                    JSONObject provider = providerTableData.getJSONObject(i);
                                    double utilization = provider.getDouble("utilization");
                                    String utilizationClass = "";
                                    if (utilization > 90) utilizationClass = "utilization-high";
                                    else if (utilization > 70) utilizationClass = "utilization-medium";
                                    else utilizationClass = "utilization-low";
                                %>
                                <tr>
                                    <td><%= provider.getString("name") %></td>
                                    <td><%= provider.getString("speciality") %></td>
                                    <td><span class="badge badge-encounters rounded-pill"><%= provider.getInt("encounters") %></span></td>
                                    <td><span class="badge badge-procedures rounded-pill"><%= provider.getInt("procedures") %></span></td>
                                    <td><span class="badge badge-claims rounded-pill"><%= provider.getInt("claims_count") %></span></td>
                                    <td><span class="<%= utilizationClass %>"><%= utilization %>%</span></td>
                                    <td><%= utilization > 90 ? "High" : utilization > 70 ? "Medium" : "Low" %></td>
                                </tr>
                                <% 
                                }
                                %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- JavaScript Libraries -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>

    <script>
    // Define the renderCharts function first
    function renderCharts(activityData, topProvidersData) {
        // Activity Distribution Pie Chart
        const activityCtx = document.getElementById('activityChart').getContext('2d');
        const activityChart = new Chart(activityCtx, {
            type: 'doughnut',
            data: {
                labels: ['Patient Encounters', 'Medical Procedures', 'Claims Processed'],
                datasets: [{
                    data: [activityData.encounters, activityData.procedures, activityData.claims],
                    backgroundColor: [
                        'rgba(52, 152, 219, 0.8)',
                        'rgba(231, 76, 60, 0.8)',
                        'rgba(46, 204, 113, 0.8)'
                    ],
                    borderColor: [
                        'rgba(52, 152, 219, 1)',
                        'rgba(231, 76, 60, 1)',
                        'rgba(46, 204, 113, 1)'
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'right',
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                const label = context.label || '';
                                const value = context.raw || 0;
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const percentage = Math.round((value / total) * 100);
                                return `${label}: ${value} (${percentage}%)`;
                            }
                        }
                    }
                }
            }
        });

        // Top Providers Bar Chart
        const topProvidersCtx = document.getElementById('topProvidersChart').getContext('2d');
        const topProvidersChart = new Chart(topProvidersCtx, {
            type: 'bar',
            data: {
                labels: topProvidersData.map(provider => provider.name),
                datasets: [{
                    label: 'Encounters',
                    data: topProvidersData.map(provider => provider.encounters),
                    backgroundColor: 'rgba(52, 152, 219, 0.7)',
                    borderColor: 'rgba(52, 152, 219, 1)',
                    borderWidth: 1
                }, {
                    label: 'Procedures',
                    data: topProvidersData.map(provider => provider.procedures),
                    backgroundColor: 'rgba(231, 76, 60, 0.7)',
                    borderColor: 'rgba(231, 76, 60, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Count'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Providers'
                        }
                    }
                }
            }
        });
    }

    // Initialize charts when DOM is loaded
    document.addEventListener('DOMContentLoaded', function() {
        try {
            const activityData = {
                encounters: <%= activityData.getInt("encounters") %>,
                procedures: <%= activityData.getInt("procedures") %>,
                claims: <%= activityData.getInt("claims") %>
            };

            const topProvidersData = [
                <% for (int i = 0; i < topProvidersData.length(); i++) {
                    JSONObject provider = topProvidersData.getJSONObject(i); %>
                    {
                        name: '<%= provider.getString("name").replace("'", "\\'").replace("\"", "\\\"") %>',
                        encounters: <%= provider.getInt("encounters") %>,
                        procedures: <%= provider.getInt("procedures") %>
                    }<%= i < topProvidersData.length() - 1 ? "," : "" %>
                <% } %>
            ];

            renderCharts(activityData, topProvidersData);
        } catch (e) {
            console.error("Error initializing charts:", e);
        }
    });

    function loadProviderData() {
        renderCharts(activityData, topProvidersData);
        refreshTable(providerTableData);
    }

    function refreshTable(data) {
        const tbody = $('#providerTableBody');
        tbody.empty();

        data.forEach(provider => {
            const utilization = provider.utilization;
            let utilizationClass = '';
            if (utilization > 90) utilizationClass = 'utilization-high';
            else if (utilization > 70) utilizationClass = 'utilization-medium';
            else utilizationClass = 'utilization-low';

            const status = utilization > 90 ? 'High' : utilization > 70 ? 'Medium' : 'Low';

            tbody.append(`
                <tr>
                    <td>${provider.name}</td>
                    <td>${provider.speciality}</td>
                    <td><span class="badge badge-encounters rounded-pill">${provider.encounters}</span></td>
                    <td><span class="badge badge-procedures rounded-pill">${provider.procedures}</span></td>
                    <td><span class="badge badge-claims rounded-pill">${provider.claims_count}</span></td>
                    <td><span class="${utilizationClass}">${utilization}%</span></td>
                    <td>${status}</td>
                </tr>
            `);
        });
    }

    function exportToPDF() {
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF('p', 'pt', 'a4');

        // Use html2canvas to capture the content
        html2canvas(document.querySelector(".container-fluid")).then(canvas => {
            const imgData = canvas.toDataURL('image/png');
            const imgWidth = doc.internal.pageSize.getWidth() - 20;
            const imgHeight = (canvas.height * imgWidth) / canvas.width;

            doc.addImage(imgData, 'PNG', 10, 10, imgWidth, imgHeight);
            doc.save('provider-activity-report.pdf');
        });
    }
    </script>
    <br>
    <h6>Note: </h6>
    <h6 style="color: black">* Utilization=(Providers Encounters/Maximum Encounters)* 100</h6>
    <h6 style="color: black">* Maximum Encounters: The assumption for the utilization calculation is based on the provider with the maximum encounters in the database.</h6>
    
</body>
</html>
