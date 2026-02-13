<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="exam-common.jspf" %>
<%
    if (isLoggedIn(session)) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    String error = "";
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        username = username == null ? "" : username.trim().toLowerCase();

        Map<String, String> user = users.get(username);
        if (user == null || !hashPassword(password == null ? "" : password).equals(user.get("passwordHash"))) {
            error = "Invalid username or password.";
        } else {
            session.setAttribute("authUser", username);
            session.setAttribute("authName", user.get("fullName"));
            session.setAttribute("authRole", user.get("role") == null ? "student" : user.get("role"));
            response.sendRedirect("dashboard.jsp");
            return;
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Portal Access | Exam Grid 2050</title>
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
<body class="min-h-screen font-body text-slate-100 bg-slate-950 overflow-x-hidden">
<div class="fixed inset-0 -z-10 bg-[radial-gradient(circle_at_15%_15%,rgba(16,185,129,0.22),transparent_30%),radial-gradient(circle_at_80%_20%,rgba(59,130,246,0.3),transparent_35%),linear-gradient(145deg,#020617,#0b1123_55%,#111827)]"></div>
<div class="max-w-6xl mx-auto px-4 py-10 md:py-16 grid md:grid-cols-2 gap-8 items-center">
    <section>
        <p class="uppercase tracking-[0.35em] text-emerald-300 text-xs">Exam Grid 2050</p>
        <h1 class="font-display text-4xl md:text-6xl leading-tight mt-3">Neural Assessment Portal</h1>
        <p class="text-slate-300 mt-4 max-w-lg">Multi-track certification exams with timed execution, instant scoring, and performance analytics.</p>
        <div class="grid grid-cols-3 gap-3 mt-8 max-w-lg">
            <div class="rounded-xl border border-cyan-400/30 bg-cyan-500/10 px-3 py-4">
                <p class="text-xs text-cyan-200">Tracks</p>
                <p class="text-2xl font-semibold"><%= testCatalog.size() %></p>
            </div>
            <div class="rounded-xl border border-emerald-400/30 bg-emerald-500/10 px-3 py-4">
                <p class="text-xs text-emerald-200">Questions</p>
                <p class="text-2xl font-semibold"><%= totalQuestionsAcrossTests %></p>
            </div>
            <div class="rounded-xl border border-blue-400/30 bg-blue-500/10 px-3 py-4">
                <p class="text-xs text-blue-200">Mode</p>
                <p class="text-2xl font-semibold">Live</p>
            </div>
        </div>
    </section>

    <section class="rounded-3xl border border-white/15 bg-white/10 backdrop-blur-xl p-7 md:p-9 shadow-2xl shadow-cyan-900/20">
        <h2 class="font-display text-2xl">Student Login</h2>
        <p class="text-slate-300 mt-2">Authenticate to continue to your command dashboard.</p>

        <% if (!error.isEmpty()) { %>
        <div class="mt-4 rounded-lg border border-red-400/40 bg-red-500/15 px-4 py-3 text-red-200"><%= esc(error) %></div>
        <% } %>

        <form method="post" class="mt-6 space-y-4">
            <div>
                <label class="text-xs uppercase tracking-[0.18em] text-slate-300">Username</label>
                <input name="username" required class="mt-2 w-full rounded-xl border border-white/20 bg-slate-900/70 px-3 py-3 outline-none focus:border-cyan-300" placeholder="enter username">
            </div>
            <div>
                <label class="text-xs uppercase tracking-[0.18em] text-slate-300">Password</label>
                <input type="password" name="password" required class="mt-2 w-full rounded-xl border border-white/20 bg-slate-900/70 px-3 py-3 outline-none focus:border-cyan-300" placeholder="enter password">
            </div>
            <button class="w-full rounded-xl bg-gradient-to-r from-cyan-400 to-emerald-400 text-slate-900 font-semibold py-3 hover:brightness-110 transition">Enter Grid</button>
        </form>

        <p class="mt-5 text-sm text-slate-300">No account yet?
            <a class="text-emerald-300 hover:underline" href="signup.jsp">Create one</a>
        </p>
    </section>
</div>
</body>
</html>
