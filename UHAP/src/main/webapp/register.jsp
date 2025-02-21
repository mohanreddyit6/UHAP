<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

    <%@page import="java.sql.*" %>

<% 

String first_name = request.getParameter("firstname");
String last_name = request.getParameter("lastname");
long user_phone = (Long.parseLong(request.getParameter("phone")));
String user_email = request.getParameter("email");
String user_password = request.getParameter("pwd");
String user_security_question = request.getParameter("hintOpt");
String user_security_ans = request.getParameter("hint");
try{	
	
	Class.forName("com.mysql.cj.jdbc.Driver");
	Connection con = DriverManager.getConnection("jdbc:mysql://localhost:3306/syntea_data","root","Mohanasahi36*");
	Statement stmt = con.createStatement();
	
	PreparedStatement ps = con.prepareStatement("INSERT INTO register VALUES (?,?,?,?,?,?,?);");
	ps.setString(1, first_name);
	ps.setString(2, last_name);
	ps.setLong(3,user_phone);
	ps.setString(4,user_email);
	ps.setString(5,user_password);
	ps.setString(6,user_security_question);
	ps.setString(7,user_security_ans);
	
	if (ps.executeUpdate() == 1) {
		response.sendRedirect("login.html");
	}
	else {
		System.out.println("<p>Registeration Failed !!!</p>");
		}
}
catch (SQLException e) {
    e.printStackTrace();
}

%>    