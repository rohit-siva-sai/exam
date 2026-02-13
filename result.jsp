<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="exam-common.jspf" %>
<%
    if (!isLoggedIn(session)) {
        response.sendRedirect("login.jsp");
        return;
    }

    String username = currentUser(session);
    String attemptId = request.getParameter("attemptId");
    Map<String, Object> selected = null;

    if (attemptId != null) {
        for (int i = attempts.size() - 1; i >= 0; i--) {
            Map<String, Object> at = attempts.get(i);
            if (attemptId.equals(String.valueOf(at.get("attemptId"))) && username.equals(String.valueOf(at.get("username")))) {
                selected = at;
                break;
            }
        }
    }

    if (selected == null) {
        response.sendRedirect("history.jsp");
        return;
    }

    int score = ((Number) selected.get("score")).intValue();
    int total = ((Number) selected.get("total")).intValue();
    double percent = ((Number) selected.get("percent")).doubleValue();
    double passCutoff = selected.get("passPercent") == null ? 50.0 : ((Number) selected.get("passPercent")).doubleValue();
    boolean passed = (Boolean) selected.get("passed");
    Date startTime = new Date((Long) selected.get("startTs"));
    Date endTime = new Date((Long) selected.get("endTs"));
    long spentSec = (((Long) selected.get("endTs")) - ((Long) selected.get("startTs"))) / 1000L;
    List<Map<String, Object>> review = (List<Map<String, Object>>) selected.get("review");
    int gauge = (int) Math.round(percent);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Result Lens | Exam Grid 2050</title>
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
<div class="fixed inset-0 -z-10 bg-[radial-gradient(circle_at_20%_10%,rgba(16,185,129,0.2),transparent_30%),radial-gradient(circle_at_80%_8%,rgba(14,165,233,0.25),transparent_34%),linear-gradient(145deg,#020617,#0b1123,#111827)]"></div>
<div class="max-w-6xl mx-auto px-4 py-8">
    <div class="flex items-center justify-between">
        <div>
            <p class="text-xs uppercase tracking-[0.25em] text-cyan-300"><%= esc(String.valueOf(selected.get("testId"))) %></p>
            <h1 class="font-display text-3xl md:text-4xl"><%= esc(String.valueOf(selected.get("testName"))) %></h1>
        </div>
        <a href="dashboard.jsp" class="px-4 py-2 rounded-xl border border-white/20 hover:bg-white/10">Dashboard</a>
    </div>

    <section class="grid md:grid-cols-[220px_1fr] gap-4 mt-6">
        <div class="rounded-2xl border border-white/15 bg-white/10 p-5 flex flex-col items-center justify-center">
            <div class="w-36 h-36 rounded-full grid place-items-center" style="background: conic-gradient(<%= passed ? "#34d399" : "#f87171" %> <%= gauge %>%, rgba(148,163,184,0.18) 0);">
                <div class="w-28 h-28 rounded-full bg-slate-950 grid place-items-center">
                    <p class="font-display text-2xl"><%= gauge %>%</p>
                </div>
            </div>
            <p class="mt-3 text-sm <%= passed ? "text-emerald-300" : "text-red-300" %>"><%= passed ? "PASS" : "FAIL" %></p>
        </div>

        <div class="rounded-2xl border border-white/15 bg-white/10 p-5">
            <div class="grid sm:grid-cols-4 gap-3">
                <div class="rounded-xl bg-slate-900/55 border border-white/10 p-3">
                    <p class="text-xs text-slate-400">Score</p>
                    <p class="text-2xl font-semibold"><%= score %>/<%= total %></p>
                </div>
                <div class="rounded-xl bg-slate-900/55 border border-white/10 p-3">
                    <p class="text-xs text-slate-400">Accuracy</p>
                    <p class="text-2xl font-semibold"><%= String.format("%.2f", percent) %>%</p>
                </div>
                <div class="rounded-xl bg-slate-900/55 border border-white/10 p-3">
                    <p class="text-xs text-slate-400">Pass Cutoff</p>
                    <p class="text-2xl font-semibold"><%= String.format("%.0f", passCutoff) %>%</p>
                </div>
                <div class="rounded-xl bg-slate-900/55 border border-white/10 p-3">
                    <p class="text-xs text-slate-400">Time Spent</p>
                    <p class="text-2xl font-semibold"><%= spentSec %>s</p>
                </div>
            </div>
            <div class="mt-4 text-sm text-slate-300">
                <p><span class="text-slate-400">Started:</span> <%= esc(startTime.toString()) %></p>
                <p><span class="text-slate-400">Submitted:</span> <%= esc(endTime.toString()) %></p>
                <p><span class="text-slate-400">Attempt ID:</span> <span class="font-mono text-xs"><%= esc(String.valueOf(selected.get("attemptId"))) %></span></p>
            </div>
        </div>
    </section>

    <section class="rounded-2xl border border-white/15 bg-white/10 p-5 mt-6">
        <h2 class="font-display text-2xl">Answer Audit</h2>
        <div class="mt-4 grid gap-3">
            <% for (Map<String, Object> r : review) {
                String[] options = (String[]) r.get("options");
                int s = (Integer) r.get("selected");
                int c = (Integer) r.get("correct");
                boolean ok = (Boolean) r.get("isCorrect");
            %>
            <article class="rounded-xl border <%= ok ? "border-emerald-400/30 bg-emerald-500/10" : "border-red-400/30 bg-red-500/10" %> p-4">
                <p class="font-medium"><%= esc(String.valueOf(r.get("qid"))) %>. <%= esc(String.valueOf(r.get("question"))) %></p>
                <p class="text-sm mt-2 <%= ok ? "text-emerald-200" : "text-red-200" %>">Your answer: <%= s >= 0 ? esc(options[s]) : "Not answered" %></p>
                <p class="text-sm text-cyan-200">Correct answer: <%= esc(options[c]) %></p>
            </article>
            <% } %>
        </div>
    </section>
</div>
</body>
</html>
