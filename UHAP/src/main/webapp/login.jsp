<%@ page import="java.sql.*"%>

<%
//DB connection
String url = application.getInitParameter("dbUrl");
String user = application.getInitParameter("dbUser");
String password = application.getInitParameter("dbPassword");

Class.forName("com.mysql.cj.jdbc.Driver");
// Connection con = DriverManager.getConnection(url, user, password);

String login_email = request.getParameter("email");
String login_password = request.getParameter("pwd");

try {
	Class.forName("com.mysql.cj.jdbc.Driver");
	Connection con = DriverManager.getConnection(url, user, password);

	PreparedStatement ps = con.prepareStatement("SELECT email, pwd FROM register WHERE email = ?");
	ps.setString(1, login_email);
	ResultSet rs = ps.executeQuery();

	if (rs.next()) {
		// Print the values retrieved from the database for debugging
		String storedEmail = rs.getString("email");
		String storedPassword = rs.getString("pwd");

		out.println("Database Email: " + storedEmail + "<br>");
		out.println("Database Password: " + storedPassword + "<br>");
		out.println("Entered Email: " + login_email + "<br>");
		out.println("Entered Password: " + login_password + "<br>");

		// Match passwords (since it's plain text)
		if (storedPassword.equals(login_password)) {
	session.setAttribute("loggedIn", true);
	session.setAttribute("username", login_email);
	response.sendRedirect("main.jsp");
		} else {
	out.println("<script>alert('Invalid Password!'); window.history.back();</script>");
		}
	} else {
		out.println("<script>alert('User not found! Please check your email.'); window.history.back();</script>");
	}

	rs.close();
	ps.close();
	con.close();

} catch (SQLException e) {
	e.printStackTrace();
	out.println("<script>alert('Database Error: " + e.getMessage() + "'); window.history.back();</script>");
}
%>
