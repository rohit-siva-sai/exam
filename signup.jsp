<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="exam-common.jspf" %>
<%
    String message = "";
    String error = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String fullName = request.getParameter("fullName");
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");

        fullName = fullName == null ? "" : fullName.trim();
        username = username == null ? "" : username.trim().toLowerCase();

        if (fullName.isEmpty() || username.isEmpty() || password == null || password.isEmpty()) {
            error = "All fields are required.";
        } else if (!password.equals(confirmPassword)) {
            error = "Password and confirm password do not match.";
        } else if (users.containsKey(username)) {
            error = "Username already exists. Please choose another.";
        } else {
            Map<String, String> user = new HashMap<String, String>();
            user.put("fullName", fullName);
            user.put("username", username);
            user.put("passwordHash", hashPassword(password));
            user.put("createdAt", new Date().toString());
            user.put("role", "student");
            users.put(username, user);
            message = "Account created successfully. Please login.";
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enrollment | Exam Grid 2050</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        display: ['Orbitron', 'sans-serif'],
                        body: ['Space Grotesk', 'sans-serif']
                    }
                }
            }
        }
    </script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@500;700;800&family=Space+Grotesk:wght@400;500;600;700&display=swap');
    </style>
</head>
<body class="min-h-screen font-body text-slate-100 bg-slate-950">
<div class="fixed inset-0 -z-10 bg-[radial-gradient(circle_at_20%_20%,rgba(14,165,233,0.28),transparent_30%),radial-gradient(circle_at_75%_0%,rgba(16,185,129,0.25),transparent_35%),linear-gradient(165deg,#020617,#0f172a,#111827)]"></div>
<div class="max-w-2xl mx-auto px-4 py-12 md:py-16">
    <div class="rounded-3xl border border-white/15 bg-white/10 backdrop-blur-xl p-7 md:p-9 shadow-2xl shadow-cyan-950/30">
        <p class="uppercase tracking-[0.3em] text-cyan-300 text-xs">New Student</p>
        <h1 class="font-display text-3xl md:text-4xl mt-2">Identity Enrollment</h1>
        <p class="text-slate-300 mt-2">Create your account to access advanced test tracks and analytics.</p>

        <% if (!error.isEmpty()) { %>
        <div class="mt-4 rounded-lg border border-red-400/40 bg-red-500/15 px-4 py-3 text-red-200"><%= esc(error) %></div>
        <% } %>
        <% if (!message.isEmpty()) { %>
        <div class="mt-4 rounded-lg border border-emerald-400/40 bg-emerald-500/15 px-4 py-3 text-emerald-200"><%= esc(message) %></div>
        <% } %>

        <form method="post" class="mt-6 grid gap-4">
            <input name="fullName" placeholder="full name" class="w-full rounded-xl border border-white/20 bg-slate-900/70 px-3 py-3 outline-none focus:border-cyan-300" required>
            <input name="username" placeholder="username" class="w-full rounded-xl border border-white/20 bg-slate-900/70 px-3 py-3 outline-none focus:border-cyan-300" required>
            <input type="password" name="password" placeholder="password" class="w-full rounded-xl border border-white/20 bg-slate-900/70 px-3 py-3 outline-none focus:border-cyan-300" required>
            <input type="password" name="confirmPassword" placeholder="confirm password" class="w-full rounded-xl border border-white/20 bg-slate-900/70 px-3 py-3 outline-none focus:border-cyan-300" required>
            <button class="w-full rounded-xl bg-gradient-to-r from-cyan-400 to-emerald-400 text-slate-900 font-semibold py-3 hover:brightness-110 transition">Register Identity</button>
        </form>

        <p class="mt-5 text-sm text-slate-300">Already registered?
            <a class="text-cyan-300 hover:underline" href="login.jsp">Login</a>
        </p>
    </div>
</div>
</body>
</html>
