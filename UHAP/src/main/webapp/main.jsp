<!-- main.jsp -->
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Healthcare Analytics Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <style>
        body {
            margin: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f6f9;
        }
        .wrapper {
            display: flex;
            min-height: 100vh;
        }
        .sidebar {
            width: 250px;
            background-color: #e9f5f2;
            padding-top: 20px;
            box-shadow: 2px 0 5px rgba(0,0,0,0.1);
        }
        .sidebar h5 {
            font-weight: bold;
            color: #2c3e50;
            padding-bottom: 15px;
        }
        .sidebar a {
            display: flex;
            align-items: center;
            padding: 12px 20px;
            color: #333;
            text-decoration: none;
            transition: background-color 0.3s ease;
            border-left: 5px solid transparent;
        }
        .sidebar a:hover, .sidebar a.active {
            background-color: #d0f0e8;
            border-left: 5px solid #00b894;
            color: #00b894;
            font-weight: bold;
        }
        .content {
            flex: 1;
            padding: 30px;
        }
        .welcome-box {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        .welcome-box h1 {
            color: #2d3436;
            font-weight: 600;
        }
        .welcome-box p {
            font-size: 18px;
            color: #636e72;
        }
        .welcome-icon {
            font-size: 95px;
            color: #00b894;
            margin-bottom: 75px;
        }
        .welcome-icon img {
            width: 650px;
        }
        iframe {
            width: 100%;
            height: calc(100vh - 60px);
            border: none;
        }
    </style>
</head>
<body>
<div class="wrapper">
    <div class="sidebar">
        <h5 class="text-center">Healthcare Analytics</h5>
        <a href="#" class="active" onclick="loadPage('welcome')">Dashboard</a>
        <a href="#" onclick="loadPage('patient_visit_trends.jsp')">Patient Visit Trends</a>
        <a href="#" onclick="loadPage('resource_data.jsp')">Resource Utilization</a>
        <a href="#" onclick="loadPage('provider_activity.jsp')">Provider Activity</a>
        <a href="#" onclick="loadPage('financial_claims.jsp')">Financial Claims</a>
    </div>
    <div class="content">
        <div id="frameContainer">
            <!-- Default welcome view -->
            <div id="welcomeView">
                <div class="welcome-box">
                    <div class="welcome-icon">
                        <img src="./Assets/index2.png" alt="Welcome Icon">
                    </div>
                    <h1>Welcome to Healthcare Analytics Dashboard</h1>
                    <br><br>
                    <h3>This dashboard helps you explore</h3>
                    <p>Patient Visit Trends</p>
                    <p>Resource Usage</p>
                    <p>Provider Activity</p>
                    <p>Financial Claims</p>
                    <br>
                    <h3>Use the menu on the left to begin navigating through insights.</h3>
                </div>
            </div>
            <iframe id="contentFrame" style="display: none;"></iframe>
        </div>
    </div>
</div>

<script>
function loadPage(page) {
    const welcomeView = document.getElementById("welcomeView");
    const frame = document.getElementById("contentFrame");
    if (page === 'welcome') {
        welcomeView.style.display = 'block';
        frame.style.display = 'none';
    } else {
        welcomeView.style.display = 'none';
        frame.style.display = 'block';
        frame.src = page;
    }
    $('.sidebar a').removeClass('active');
    event.target.classList.add('active');
}
</script>
</body>
</html>
