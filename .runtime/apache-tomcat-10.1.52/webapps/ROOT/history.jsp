<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="exam-common.jspf" %>
<%
    if (!isLoggedIn(session)) {
        response.sendRedirect("login.jsp");
        return;
    }

    String username = currentUser(session);
    List<Map<String, Object>> mine = new ArrayList<Map<String, Object>>();
    for (int i = attempts.size() - 1; i >= 0; i--) {
        Map<String, Object> at = attempts.get(i);
        if (username.equals(String.valueOf(at.get("username")))) {
            mine.add(at);
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Result Stream | Exam Grid 2050</title>
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
<div class="fixed inset-0 -z-10 bg-[radial-gradient(circle_at_20%_10%,rgba(59,130,246,0.2),transparent_30%),radial-gradient(circle_at_80%_8%,rgba(16,185,129,0.2),transparent_34%),linear-gradient(145deg,#020617,#0b1123,#111827)]"></div>
<div class="max-w-7xl mx-auto px-4 py-8">
    <div class="flex items-center justify-between mb-5">
        <div>
            <p class="text-xs uppercase tracking-[0.25em] text-cyan-300">Progress Ledger</p>
            <h1 class="font-display text-3xl md:text-4xl">Result Stream</h1>
        </div>
        <a href="dashboard.jsp" class="px-4 py-2 rounded-xl border border-white/20 hover:bg-white/10">Dashboard</a>
    </div>

    <section class="rounded-2xl border border-white/15 bg-white/10 backdrop-blur-xl overflow-x-auto">
        <table class="w-full text-left min-w-[840px]">
            <thead class="bg-slate-900/70 text-slate-200 text-sm uppercase tracking-[0.12em]">
            <tr>
                <th class="px-4 py-3">Track</th>
                <th class="px-4 py-3">Attempt ID</th>
                <th class="px-4 py-3">Score</th>
                <th class="px-4 py-3">Percent</th>
                <th class="px-4 py-3">Status</th>
                <th class="px-4 py-3">Submitted</th>
                <th class="px-4 py-3">Action</th>
            </tr>
            </thead>
            <tbody>
            <% if (mine.isEmpty()) { %>
            <tr>
                <td colspan="7" class="px-4 py-8 text-center text-slate-300">No attempts yet. Start a track from dashboard.</td>
            </tr>
            <% } else {
                for (Map<String, Object> at : mine) { %>
            <tr class="border-t border-white/10">
                <td class="px-4 py-3">
                    <p class="font-semibold"><%= esc(String.valueOf(at.get("testName"))) %></p>
                    <p class="text-xs text-slate-400"><%= esc(String.valueOf(at.get("testId"))) %></p>
                </td>
                <td class="px-4 py-3 font-mono text-xs text-slate-300"><%= esc(String.valueOf(at.get("attemptId"))) %></td>
                <td class="px-4 py-3"><%= at.get("score") %> / <%= at.get("total") %></td>
                <td class="px-4 py-3"><%= String.format("%.2f", ((Number) at.get("percent")).doubleValue()) %>%</td>
                <td class="px-4 py-3 <%= ((Boolean) at.get("passed")) ? "text-emerald-300" : "text-red-300" %>"><%= ((Boolean) at.get("passed")) ? "PASS" : "FAIL" %></td>
                <td class="px-4 py-3 text-sm"><%= esc(new Date((Long) at.get("endTs")).toString()) %></td>
                <td class="px-4 py-3"><a class="text-cyan-300 hover:underline" href="result.jsp?attemptId=<%= URLEncoder.encode(String.valueOf(at.get("attemptId")), "UTF-8") %>">Open</a></td>
            </tr>
            <% }
            } %>
            </tbody>
        </table>
    </section>
</div>
</body>
</html>
