<%@ page
	import="java.sql.*, org.json.simple.JSONArray, org.json.simple.JSONObject"%>
<%@ page contentType="text/html;charset=UTF-8" language="java"%>
<!DOCTYPE html>
<html>
<head>
<title>Patient Visit Trends</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
</head>
<body>
	<div class="container mt-4">
		<h3 class="mb-4">Patient Visit Trends</h3>
		<div class="row text-center mb-4">
			<div class="col-md-3">
				<div class="card bg-primary text-white">
					<div class="card-body">
						<h5>Total Patients</h5>
						<h4>
							<%
							String url = application.getInitParameter("dbUrl");
							String user = application.getInitParameter("dbUser");
							String password = application.getInitParameter("dbPassword");
							Class.forName("com.mysql.cj.jdbc.Driver");
							Connection con = DriverManager.getConnection(url, user, password);
							Statement stmt = con.createStatement();
							ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM patients");
							if (rs.next()) out.print(rs.getInt(1));
							
						%>
						</h4>
					</div>
				</div>
			</div>
			<div class="col-md-3">
				<div class="card bg-success text-white">
					<div class="card-body">
						<h5>Alive</h5>
						<h4>
							<%
							rs = stmt.executeQuery("SELECT COUNT(*) FROM patients WHERE DEATHDATE IS NULL OR DEATHDATE = ''");
							if (rs.next()) out.print(rs.getInt(1));
						%>
						</h4>
					</div>
				</div>
			</div>
			<div class="col-md-3">
				<div class="card bg-danger text-white">
					<div class="card-body">
						<h5>Dead</h5>
						<h4>
							<%
							rs = stmt.executeQuery("SELECT COUNT(*) FROM patients WHERE DEATHDATE IS NOT NULL AND DEATHDATE != ''");
							if (rs.next()) out.print(rs.getInt(1));
						%>
						</h4>
					</div>
				</div>
			</div>
			<div class="col-md-3">
				<div class="card bg-info text-white">
					<div class="card-body">
						<h5>Avg. Monthly Visits</h5>
						<h4>
							<%
							rs = stmt.executeQuery("SELECT COUNT(*)/12 FROM encounters");
							if (rs.next()) out.print(rs.getInt(1));
							stmt.close(); con.close();
						%>
						</h4>
					</div>
				</div>
			</div>
		</div>

		<div class="card">
			<div class="card-body">
				<div class="d-flex justify-content-between">
					<h5>Visits Over Time</h5>
					<div class="d-flex gap-2">
						<select id="categorySelect" class="form-select">
							<option value="all">All</option>
							<option value="GENDER">Gender</option>
							<option value="RACE">Race</option>
							<option value="ETHNICITY">Ethnicity</option>
							<option value="CITY">City</option>
						</select>
						<button class="btn btn-outline-secondary" id="exportBtn">Save</button>
					</div>
				</div>
				<canvas id="visitChart" height="100"></canvas>
			</div>
		</div>
	</div>

	<script>
let chartInstance;
function fetchVisitData(category = "all") {
	$.ajax({
		url: "get_visit_data.jsp",
		method: "GET",
		dataType: "json",
		data: { category: category },
		success: function(data) {
			if (data.error) {
				alert("Error: " + data.error);
				return;
			}
			updateChart(data.labels, data.values, data.chartType);
		}
	});
}

function updateChart(labels, values, chartType) {
    const ctx = document.getElementById("visitChart");

    // Safely destroy existing chart using Chart.js instance tracking
    const existing = Chart.getChart(ctx);
    if (existing) {
        existing.destroy();
    }

    // Fallback for safety
    if (!chartType || (chartType !== 'line' && chartType !== 'bar')) {
        chartType = 'bar';
    }

    chartInstance = new Chart(ctx, {
        type: chartType,
        data: {
            labels: labels,
            datasets: [{
                label: "Patient Visits",
                data: values,
                backgroundColor: chartType === 'bar' ? '#4dabf7' : 'rgba(0,0,255,0.1)',
                borderColor: 'blue',
                fill: chartType === 'line',
                tension: chartType === 'line' ? 0.4 : 0,
                pointHoverRadius: 6,
                pointHoverBackgroundColor: "red"
            }]
        },
        options: {
            responsive: true,
            plugins: {
                title: {
                    display: true,
                    text: chartType === 'line' ? "Monthly Trends by Filter" : "Patient Count by Category"
                },
                legend: { display: true },
                tooltip: { enabled: true }
            }
        }
    });
}


$(document).ready(function () {
	fetchVisitData();
	$('#categorySelect').change(function () {
		fetchVisitData($(this).val());
	});
	$('#exportBtn').click(function () {
		html2canvas(document.querySelector("#visitChart")).then(canvas => {
			const imgData = canvas.toDataURL("image/png");
			const pdf = new jspdf.jsPDF();
			pdf.addImage(imgData, 'PNG', 10, 10, 180, 100);
			pdf.save("Patient_Visit_Trends.pdf");
		});
	});
});
</script>

<%
ResultSet rs2 = null;
Statement stmt2 = null;
try {
  // Ensure database connection is still open
  if (con == null || con.isClosed()) {
    Class.forName("com.mysql.cj.jdbc.Driver");
    con = DriverManager.getConnection(url, user, password);
  }
  
  stmt2 = con.createStatement();
%>

<div class="container mt-4">
<h3 class="mb-4">Predictive Insights</h3>
<div class="card mb-4">
  <div class="card-header bg-primary text-white">
    <strong>Patients Likely to Return Next Month</strong>
  </div>
  <div class="card-body">
    <canvas id="returnChart"></canvas>
  </div>
</div>
<div class="card mb-4">
  <div class="card-header bg-warning">
    <strong>Long Gap in Care (Days Since Last Visit)</strong>
  </div>
  <div class="card-body">
    <canvas id="gapChart"></canvas>
  </div>
</div>
<div class="card mb-4">
  <div class="card-header bg-success text-white">
    <strong>Multi-Visit Condition Trend</strong>
  </div>
  <div class="card-body">
    <canvas id="conditionChart"></canvas>
  </div>
</div>
</div>
<script>
let returnData = [];
let gapData = [0, 0, 0]; 
let gapLabels = ["< 90 days", "90–180 days", "180+ days"];
let conditionLabels = [];
let conditionCounts = [];
</script>
<%
rs2 = stmt2.executeQuery("SELECT COUNT(DISTINCT PATIENT) AS total FROM (SELECT PATIENT FROM encounters WHERE DATEDIFF(CURDATE(), START) <= 60 GROUP BY PATIENT HAVING COUNT(*) >= 3) AS sub");
if (rs2.next()) {
    int count = rs2.getInt("total");
%>
<script>
returnData.push(<%= count %>);
</script>
<%
}
rs2 = stmt2.executeQuery("SELECT DATEDIFF(CURDATE(), MAX(START)) AS gap_days FROM encounters GROUP BY PATIENT");
int gapLessThan90 = 0, gapBetween90And180 = 0, gapOver180 = 0;
while (rs2.next()) {
    int gap = rs2.getInt("gap_days");
    if (gap < 90) gapLessThan90++;
    else if (gap <= 180) gapBetween90And180++;
    else gapOver180++;
}
%>
<script>
gapData = [<%= gapLessThan90 %>, <%= gapBetween90And180 %>, <%= gapOver180 %>];
</script>
<%
rs2 = stmt2.executeQuery("SELECT REASONDESCRIPTION, COUNT(*) AS count FROM encounters WHERE REASONDESCRIPTION IS NOT NULL GROUP BY REASONDESCRIPTION HAVING count >= 3");
while (rs2.next()) {
    String reason = rs2.getString("REASONDESCRIPTION");
    reason = reason.replace("\"", "\\\"");  // Escape quotes properly
    int count = rs2.getInt("count");
%>
<script>
conditionLabels.push("<%= reason %>");
conditionCounts.push(<%= count %>);
</script>
<%
}
%>
<script>
document.addEventListener("DOMContentLoaded", function() {
    new Chart(document.getElementById("returnChart").getContext("2d"), {
        type: 'bar',
        data: {
            labels: ["Likely Returnees"],
            datasets: [{ 
                label: "Patients", 
                data: returnData, 
                backgroundColor: "#0984e3" 
            }]
        }
    });
    
    new Chart(document.getElementById("gapChart").getContext("2d"), {
        type: 'bar',
        data: {
            labels: gapLabels,
            datasets: [{ 
                label: "Patients", 
                data: gapData, 
                backgroundColor: ["#ffeaa7", "#fab1a0", "#d63031"] 
            }]
        }
    });
    
    new Chart(document.getElementById("conditionChart").getContext("2d"), {
        type: 'line',
        data: {
            labels: conditionLabels,
            datasets: [{ 
                label: "Visit Count", 
                data: conditionCounts, 
                backgroundColor: "#55efc4" 
            }]
        },
        options: { 
            indexAxis: 'x' 
        }
    });
});
</script>
<%
} catch (Exception e) {
    out.println("<div class='alert alert-danger'>Database error: " + e.getMessage() + "</div>");
    e.printStackTrace();
} finally {
    try {
        if (rs != null) rs.close();
        if (rs2 != null) rs2.close();
        if (stmt != null) stmt.close();
        if (stmt2 != null) stmt2.close();
        if (con != null) con.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
}
%>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>