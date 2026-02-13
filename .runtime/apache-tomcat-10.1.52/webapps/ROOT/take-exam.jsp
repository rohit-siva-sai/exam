<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="exam-common.jspf" %>
<%
    if (!isLoggedIn(session)) {
        response.sendRedirect("login.jsp");
        return;
    }

    String selectedTestId = request.getParameter("test");
    if (selectedTestId == null || selectedTestId.trim().isEmpty()) {
        Object active = session.getAttribute("examTestId");
        if (active != null) {
            selectedTestId = String.valueOf(active);
        }
    }

    Map<String, Object> selectedTest = selectedTestId == null ? null : testIndex.get(selectedTestId);

    if ("start".equals(request.getParameter("action")) && selectedTest != null) {
        int durationSec = ((Number) selectedTest.get("durationSec")).intValue();
        session.setAttribute("examStartTs", System.currentTimeMillis());
        session.setAttribute("examDurationSec", durationSec);
        session.setAttribute("examAttemptId", UUID.randomUUID().toString());
        session.setAttribute("examTestId", selectedTestId);
        session.setAttribute("examPassPercent", ((Number) selectedTest.get("passPercent")).doubleValue());
        response.sendRedirect("take-exam.jsp?test=" + URLEncoder.encode(selectedTestId, "UTF-8"));
        return;
    }

    Long startTs = (Long) session.getAttribute("examStartTs");
    Integer examDuration = (Integer) session.getAttribute("examDurationSec");
    String attemptId = (String) session.getAttribute("examAttemptId");
    String activeTestId = (String) session.getAttribute("examTestId");

    boolean started = startTs != null && examDuration != null && attemptId != null && activeTestId != null;

    if (started) {
        selectedTest = testIndex.get(activeTestId);
        selectedTestId = activeTestId;
    }

    if (selectedTest == null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    List<Map<String, Object>> questions = (List<Map<String, Object>>) selectedTest.get("questions");
    int remaining = started ? (int) ((startTs + (examDuration * 1000L) - System.currentTimeMillis()) / 1000L) : 0;
    if (remaining < 0) {
        remaining = 0;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Exam Console | <%= esc(String.valueOf(selectedTest.get("name"))) %></title>
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
<div class="fixed inset-0 -z-10 bg-[radial-gradient(circle_at_20%_10%,rgba(14,165,233,0.2),transparent_32%),radial-gradient(circle_at_82%_8%,rgba(16,185,129,0.2),transparent_32%),linear-gradient(145deg,#020617,#0b1123,#111827)]"></div>
<div class="max-w-7xl mx-auto px-4 py-7">
    <div class="flex items-center justify-between gap-3 mb-5">
        <div>
            <p class="uppercase tracking-[0.25em] text-xs text-cyan-300"><%= esc(String.valueOf(selectedTest.get("id"))) %></p>
            <h1 class="font-display text-3xl md:text-4xl"><%= esc(String.valueOf(selectedTest.get("name"))) %></h1>
        </div>
        <a href="dashboard.jsp" class="px-4 py-2 rounded-xl border border-white/20 hover:bg-white/10">Dashboard</a>
    </div>

    <% if (!started) { %>
    <section class="rounded-3xl border border-white/15 bg-white/10 backdrop-blur-xl p-7 md:p-9">
        <p class="text-slate-200"><%= esc(String.valueOf(selectedTest.get("tagline"))) %></p>
        <div class="grid md:grid-cols-3 gap-3 mt-5">
            <div class="rounded-xl border border-cyan-300/30 bg-cyan-400/10 p-4">
                <p class="text-xs text-cyan-100 uppercase tracking-[0.15em]">Questions</p>
                <p class="text-2xl font-semibold"><%= questions.size() %></p>
            </div>
            <div class="rounded-xl border border-emerald-300/30 bg-emerald-400/10 p-4">
                <p class="text-xs text-emerald-100 uppercase tracking-[0.15em]">Duration</p>
                <p class="text-2xl font-semibold"><%= ((Number) selectedTest.get("durationSec")).intValue() / 60 %> min</p>
            </div>
            <div class="rounded-xl border border-amber-300/30 bg-amber-400/10 p-4">
                <p class="text-xs text-amber-100 uppercase tracking-[0.15em]">Pass</p>
                <p class="text-2xl font-semibold"><%= String.format("%.0f", ((Number) selectedTest.get("passPercent")).doubleValue()) %>%</p>
            </div>
        </div>
        <form method="post" class="mt-6">
            <input type="hidden" name="action" value="start">
            <input type="hidden" name="test" value="<%= esc(selectedTestId) %>">
            <button class="rounded-xl bg-gradient-to-r from-cyan-400 to-emerald-400 text-slate-900 font-semibold px-7 py-3 hover:brightness-110">Start Assessment</button>
        </form>
    </section>
    <% } else { %>
    <div class="grid lg:grid-cols-[1fr_280px] gap-4">
        <section class="rounded-3xl border border-white/15 bg-white/10 backdrop-blur-xl p-5 md:p-6">
            <div class="sticky top-3 z-10 rounded-2xl border border-white/15 bg-slate-900/70 backdrop-blur p-3 mb-4 flex items-center justify-between">
                <p class="text-sm text-slate-300">Auto-submit when timer reaches zero</p>
                <p id="timer" class="font-display text-2xl text-cyan-300">--:--</p>
            </div>

            <form id="examForm" method="post" action="submit-exam.jsp" class="space-y-4">
                <input type="hidden" name="attemptId" value="<%= esc(attemptId) %>">
                <% for (int i = 0; i < questions.size(); i++) {
                    Map<String, Object> q = questions.get(i);
                    String[] options = (String[]) q.get("options");
                %>
                <article id="card-<%= i + 1 %>" class="rounded-2xl border border-white/15 bg-slate-900/45 p-4">
                    <p class="text-xs uppercase tracking-[0.2em] text-cyan-200">Question <%= i + 1 %></p>
                    <p class="font-medium text-lg mt-1"><%= esc(String.valueOf(q.get("text"))) %></p>
                    <div class="mt-3 grid gap-2">
                        <% for (int j = 0; j < options.length; j++) { %>
                        <label class="flex items-center gap-2 rounded-lg border border-white/10 px-3 py-2 hover:bg-white/10 cursor-pointer">
                            <input type="radio" name="<%= q.get("id") %>" value="<%= j %>" class="accent-emerald-400 answer-input">
                            <span><%= esc(options[j]) %></span>
                        </label>
                        <% } %>
                    </div>
                </article>
                <% } %>
                <button class="w-full rounded-xl py-3 bg-gradient-to-r from-emerald-400 to-cyan-400 text-slate-900 font-semibold hover:brightness-110">Submit Exam</button>
            </form>
        </section>

        <aside class="rounded-3xl border border-white/15 bg-white/10 backdrop-blur-xl p-4 h-fit lg:sticky lg:top-6">
            <h2 class="font-display text-xl">Question Matrix</h2>
            <p id="answeredStats" class="text-sm text-slate-300 mt-1">0 / <%= questions.size() %> answered</p>
            <div class="grid grid-cols-5 gap-2 mt-4">
                <% for (int i = 0; i < questions.size(); i++) { %>
                <button type="button" data-target="card-<%= i + 1 %>" class="q-jump rounded-lg border border-white/20 text-sm py-1 hover:bg-cyan-300/20"><%= i + 1 %></button>
                <% } %>
            </div>
        </aside>
    </div>

    <script>
        (function () {
            let secondsLeft = <%= remaining %>;
            const timerEl = document.getElementById('timer');
            const examForm = document.getElementById('examForm');
            const answers = document.querySelectorAll('.answer-input');
            const stat = document.getElementById('answeredStats');
            const jumps = document.querySelectorAll('.q-jump');

            function format(s) {
                const m = Math.floor(s / 60).toString().padStart(2, '0');
                const sec = (s % 60).toString().padStart(2, '0');
                return m + ':' + sec;
            }

            function updateAnswered() {
                const names = new Set();
                let answered = 0;
                answers.forEach(function (el) {
                    if (!names.has(el.name)) {
                        names.add(el.name);
                        if (document.querySelector('input[name="' + el.name + '"]:checked')) {
                            answered++;
                        }
                    }
                });
                stat.textContent = answered + ' / ' + names.size + ' answered';
            }

            function tick() {
                timerEl.textContent = format(secondsLeft);
                if (secondsLeft <= 0) {
                    examForm.submit();
                    return;
                }
                secondsLeft--;
                setTimeout(tick, 1000);
            }

            answers.forEach(function (a) {
                a.addEventListener('change', updateAnswered);
            });
            jumps.forEach(function (btn) {
                btn.addEventListener('click', function () {
                    const target = document.getElementById(btn.getAttribute('data-target'));
                    if (target) {
                        target.scrollIntoView({behavior: 'smooth', block: 'start'});
                    }
                });
            });

            updateAnswered();
            tick();
        })();
    </script>
    <% } %>
</div>
</body>
</html>
