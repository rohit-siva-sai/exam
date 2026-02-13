<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="exam-common.jspf" %>
<%
    if (!isLoggedIn(session)) {
        response.sendRedirect("login.jsp");
        return;
    }

    String username = currentUser(session);
    String fullName = (String) session.getAttribute("authName");
    boolean admin = isAdmin(session);

    int totalAttempts = 0;
    double bestPercent = 0;
    double avgPercent = 0;

    for (Map<String, Object> at : attempts) {
        if (username.equals(String.valueOf(at.get("username")))) {
            totalAttempts++;
            double p = ((Number) at.get("percent")).doubleValue();
            avgPercent += p;
            if (p > bestPercent) {
                bestPercent = p;
            }
        }
    }
    if (totalAttempts > 0) {
        avgPercent = avgPercent / totalAttempts;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Command Deck | Exam Grid 2050</title>
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
<div class="fixed inset-0 -z-10 bg-[radial-gradient(circle_at_15%_10%,rgba(34,211,238,0.2),transparent_30%),radial-gradient(circle_at_80%_5%,rgba(16,185,129,0.25),transparent_34%),linear-gradient(145deg,#020617,#0b1123,#111827)]"></div>
<div class="max-w-7xl mx-auto px-4 py-8 md:py-10">
    <header class="rounded-3xl border border-white/15 bg-white/10 backdrop-blur-xl p-6 md:p-8 shadow-2xl shadow-cyan-900/20">
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <p class="uppercase tracking-[0.3em] text-cyan-300 text-xs">Command Deck</p>
                <h1 class="font-display text-3xl md:text-5xl mt-2">Welcome, <%= esc(fullName) %></h1>
                <p class="text-slate-300 mt-2">Identity: <span class="font-mono"><%= esc(username) %></span></p>
            </div>
            <div class="flex gap-3">
                <% if (admin) { %>
                <a href="admin.jsp" class="px-4 py-2 rounded-xl border border-emerald-300/40 text-emerald-200 hover:bg-emerald-400/15">Admin Control</a>
                <% } %>
                <a href="history.jsp" class="px-4 py-2 rounded-xl border border-cyan-300/40 text-cyan-200 hover:bg-cyan-400/15">Result Stream</a>
                <a href="logout.jsp" class="px-4 py-2 rounded-xl bg-red-500/80 hover:bg-red-500 text-white">Logout</a>
            </div>
        </div>

        <div class="grid md:grid-cols-4 gap-3 mt-6">
            <div class="rounded-xl border border-cyan-400/30 bg-cyan-500/10 p-4">
                <p class="text-xs uppercase tracking-[0.18em] text-cyan-100">Tracks</p>
                <p class="text-3xl font-semibold mt-1"><%= testCatalog.size() %></p>
            </div>
            <div class="rounded-xl border border-emerald-400/30 bg-emerald-500/10 p-4">
                <p class="text-xs uppercase tracking-[0.18em] text-emerald-100">Question Pool</p>
                <p class="text-3xl font-semibold mt-1"><%= totalQuestionsAcrossTests %></p>
            </div>
            <div class="rounded-xl border border-blue-400/30 bg-blue-500/10 p-4">
                <p class="text-xs uppercase tracking-[0.18em] text-blue-100">Attempts</p>
                <p class="text-3xl font-semibold mt-1"><%= totalAttempts %></p>
            </div>
            <div class="rounded-xl border border-violet-400/30 bg-violet-500/10 p-4">
                <p class="text-xs uppercase tracking-[0.18em] text-violet-100">Best / Avg</p>
                <p class="text-3xl font-semibold mt-1"><%= String.format("%.1f", bestPercent) %>%</p>
                <p class="text-xs text-violet-100/80 mt-1">avg <%= String.format("%.1f", avgPercent) %>%</p>
            </div>
        </div>
    </header>

    <section class="mt-8">
        <div class="flex items-end justify-between mb-4">
            <h2 class="font-display text-2xl md:text-3xl">Available Exam Tracks</h2>
            <p class="text-slate-300 text-sm">Auto-submit enabled on timeout</p>
        </div>

        <div class="grid lg:grid-cols-3 gap-4">
            <% for (Map<String, Object> t : testCatalog) {
                String testId = String.valueOf(t.get("id"));
                String testName = String.valueOf(t.get("name"));
                String tagline = String.valueOf(t.get("tagline"));
                int duration = ((Number) t.get("durationSec")).intValue();
                double passPercent = ((Number) t.get("passPercent")).doubleValue();
                List<Map<String, Object>> qs = (List<Map<String, Object>>) t.get("questions");
            %>
            <article class="rounded-2xl border border-white/15 bg-white/10 backdrop-blur-md p-5 shadow-xl shadow-slate-950/30">
                <p class="text-xs uppercase tracking-[0.22em] text-cyan-200"><%= esc(testId) %></p>
                <h3 class="font-display text-2xl mt-2"><%= esc(testName) %></h3>
                <p class="text-slate-300 mt-2 min-h-12"><%= esc(tagline) %></p>
                <div class="grid grid-cols-3 gap-2 mt-4 text-center">
                    <div class="rounded-lg bg-slate-900/50 p-2 border border-white/10">
                        <p class="text-[11px] text-slate-400">Questions</p>
                        <p class="font-semibold"><%= qs.size() %></p>
                    </div>
                    <div class="rounded-lg bg-slate-900/50 p-2 border border-white/10">
                        <p class="text-[11px] text-slate-400">Minutes</p>
                        <p class="font-semibold"><%= duration / 60 %></p>
                    </div>
                    <div class="rounded-lg bg-slate-900/50 p-2 border border-white/10">
                        <p class="text-[11px] text-slate-400">Pass</p>
                        <p class="font-semibold"><%= String.format("%.0f", passPercent) %>%</p>
                    </div>
                </div>
                <a href="take-exam.jsp?test=<%= URLEncoder.encode(testId, "UTF-8") %>" class="mt-5 inline-block w-full text-center rounded-xl py-2 bg-gradient-to-r from-cyan-400 to-emerald-400 text-slate-900 font-semibold hover:brightness-110">Launch Track</a>
            </article>
            <% } %>
        </div>
    </section>
</div>
</body>
</html>
