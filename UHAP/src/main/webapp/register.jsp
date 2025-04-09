<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.sql.*"%>

<%
//DB connection
String url = application.getInitParameter("dbUrl");
String user = application.getInitParameter("dbUser");
String password = application.getInitParameter("dbPassword");

Class.forName("com.mysql.cj.jdbc.Driver");
// Connection con = DriverManager.getConnection(url, user, password);

String first_name = request.getParameter("firstname");
String last_name = request.getParameter("lastname");
String phoneParam = request.getParameter("phone");
String user_email = request.getParameter("email");
String user_password = request.getParameter("pwd");
String user_security_question = request.getParameter("hintOpt");
String user_security_ans = request.getParameter("hint");

// Validate empty fields
if (first_name == null || last_name == null || phoneParam == null || user_email == null || user_password == null
		|| user_security_question == null || user_security_ans == null || first_name.trim().isEmpty()
		|| last_name.trim().isEmpty() || phoneParam.trim().isEmpty() || user_email.trim().isEmpty()
		|| user_password.trim().isEmpty() || user_security_ans.trim().isEmpty()) {

	out.println("<script>alert('All fields are required!'); window.history.back();</script>");
	return;
}

// Validate phone number
long user_phone = 0;
try {
	user_phone = Long.parseLong(phoneParam);
} catch (NumberFormatException e) {
	out.println("<script>alert('Invalid phone number. Please enter digits only.'); window.history.back();</script>");
	return;
}

try {
	// Load MySQL driver
	Class.forName("com.mysql.cj.jdbc.Driver");
	Connection con = DriverManager.getConnection(url, user, password);

	// **Check if email already exists**
	PreparedStatement checkUser = con.prepareStatement("SELECT email FROM register WHERE email = ?");
	checkUser.setString(1, user_email);
	ResultSet rs = checkUser.executeQuery();

	if (rs.next()) {
		out.println(
		"<script>alert('Email already registered! Please use a different email.'); window.history.back();</script>");
		return;
	}
	rs.close();
	checkUser.close();

	// **Hash the password using BCrypt**
	// <%@ page import="org.mindrot.jbcrypt.BCrypt" 
	// String hashedPassword = BCrypt.hashpw(user_password, BCrypt.gensalt());

	// **Insert new user into the database**
	String query = "INSERT INTO register (firstname, lastname, phone, email, pwd, hintOpt, hint) VALUES (?, ?, ?, ?, ?, ?, ?)";
	PreparedStatement ps = con.prepareStatement(query);
	ps.setString(1, first_name);
	ps.setString(2, last_name);
	ps.setLong(3, user_phone);
	ps.setString(4, user_email);
	ps.setString(5, user_password);
	ps.setString(6, user_security_question);
	ps.setString(7, user_security_ans);

	int rowsInserted = ps.executeUpdate();

	if (rowsInserted > 0) {
		out.println("<script>alert('Registration Successful!'); window.location='login.html';</script>");
	} else {
		out.println("<script>alert('Registration Failed! Please try again.'); window.history.back();</script>");
	}

	// Close database resources
	ps.close();
	con.close();

} catch (SQLException e) {
	e.printStackTrace();
	out.println("<script>alert('Database Error: " + e.getMessage() + "'); window.history.back();</script>");
}
%>
