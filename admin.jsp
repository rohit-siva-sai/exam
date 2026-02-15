<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.net.http.*, java.net.URI, java.time.Duration" %>
<%@ include file="exam-common.jspf" %>
<%!
    public String jsonEscape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }

    public String jsonUnescape(String s) {
        if (s == null) return "";
        StringBuilder out = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '\\' && i + 1 < s.length()) {
                char n = s.charAt(++i);
                if (n == 'n') out.append('\n');
                else if (n == 'r') out.append('\r');
                else if (n == 't') out.append('\t');
                else if (n == '"') out.append('"');
                else if (n == '\\') out.append('\\');
                else if (n == 'u' && i + 4 < s.length()) {
                    String hex = s.substring(i + 1, i + 5);
                    try {
                        out.append((char) Integer.parseInt(hex, 16));
                        i += 4;
                    } catch (Exception ignore) {
                        out.append("\\u").append(hex);
                        i += 4;
                    }
                } else {
                    out.append(n);
                }
            } else {
                out.append(c);
            }
        }
        return out.toString();
    }

    public String extractJsonStringField(String json, String key) {
        if (json == null || key == null || key.isEmpty()) return null;
        String needle = "\"" + key + "\"";
        int keyPos = json.indexOf(needle);
        while (keyPos >= 0) {
            int colon = json.indexOf(':', keyPos + needle.length());
            if (colon < 0) return null;
            int i = colon + 1;
            while (i < json.length() && Character.isWhitespace(json.charAt(i))) {
                i++;
            }
            if (i < json.length() && json.charAt(i) == '"') {
                i++;
                StringBuilder sb = new StringBuilder();
                boolean escaped = false;
                while (i < json.length()) {
                    char c = json.charAt(i++);
                    if (escaped) {
                        sb.append('\\').append(c);
                        escaped = false;
                    } else if (c == '\\') {
                        escaped = true;
                    } else if (c == '"') {
                        return jsonUnescape(sb.toString());
                    } else {
                        sb.append(c);
                    }
                }
                return null;
            }
            keyPos = json.indexOf(needle, keyPos + needle.length());
        }
        return null;
    }

    public String extractFirstContent(String json) {
        return extractJsonStringField(json, "content");
    }

    public String extractFirstGeminiText(String json) {
        return extractJsonStringField(json, "text");
    }
%>
<%
    if (!isLoggedIn(session)) {
        response.sendRedirect("login.jsp");
        return;
    }
    if (!isAdmin(session)) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    String msg = "";
    String err = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");

        synchronized (application) {
            if ("createTest".equals(action)) {
                String id = request.getParameter("testId");
                String name = request.getParameter("testName");
                String tagline = request.getParameter("tagline");
                String durationMin = request.getParameter("durationMin");
                String passPercent = request.getParameter("passPercent");

                id = id == null ? "" : id.trim().toUpperCase();
                name = name == null ? "" : name.trim();
                tagline = tagline == null ? "" : tagline.trim();

                int durationSec = 0;
                double pass = 0;

                try {
                    durationSec = Integer.parseInt(durationMin) * 60;
                    pass = Double.parseDouble(passPercent);
                } catch (Exception ex) {
                    durationSec = 0;
                }

                if (id.isEmpty() || name.isEmpty() || durationSec <= 0 || pass <= 0 || pass > 100) {
                    err = "Invalid test details.";
                } else if (testIndex.containsKey(id)) {
                    err = "Test ID already exists.";
                } else {
                    List<Map<String, Object>> qs = new ArrayList<Map<String, Object>>();
                    testCatalog.add(test(id, name, tagline, durationSec, pass, qs));
                    msg = "Test created: " + id;
                }
            }

            if ("deleteTest".equals(action)) {
                String id = request.getParameter("testId");
                id = id == null ? "" : id.trim().toUpperCase();
                boolean removed = false;
                for (Iterator<Map<String, Object>> it = testCatalog.iterator(); it.hasNext();) {
                    Map<String, Object> t = it.next();
                    if (id.equals(String.valueOf(t.get("id")))) {
                        it.remove();
                        removed = true;
                        break;
                    }
                }
                if (removed) {
                    msg = "Test removed: " + id;
                } else {
                    err = "Test not found.";
                }
            }

            if ("addQuestion".equals(action)) {
                String id = request.getParameter("testId");
                String qid = request.getParameter("qid");
                String qtext = request.getParameter("qtext");
                String o1 = request.getParameter("o1");
                String o2 = request.getParameter("o2");
                String o3 = request.getParameter("o3");
                String o4 = request.getParameter("o4");
                String answer = request.getParameter("answer");

                id = id == null ? "" : id.trim().toUpperCase();
                qid = qid == null ? "" : qid.trim().toUpperCase();
                qtext = qtext == null ? "" : qtext.trim();
                o1 = o1 == null ? "" : o1.trim();
                o2 = o2 == null ? "" : o2.trim();
                o3 = o3 == null ? "" : o3.trim();
                o4 = o4 == null ? "" : o4.trim();

                Map<String, Object> t = testIndex.get(id);
                int ans = -1;
                try {
                    ans = Integer.parseInt(answer);
                } catch (Exception ignore) {
                    ans = -1;
                }

                if (t == null) {
                    err = "Target test not found.";
                } else if (qid.isEmpty() || qtext.isEmpty() || o1.isEmpty() || o2.isEmpty() || o3.isEmpty() || o4.isEmpty() || ans < 0 || ans > 3) {
                    err = "Invalid question payload.";
                } else {
                    List<Map<String, Object>> qs = (List<Map<String, Object>>) t.get("questions");
                    boolean exists = false;
                    for (Map<String, Object> q : qs) {
                        if (qid.equals(String.valueOf(q.get("id")))) {
                            exists = true;
                            break;
                        }
                    }
                    if (exists) {
                        err = "Question ID already exists in this test.";
                    } else {
                        qs.add(q(qid, qtext, new String[]{o1, o2, o3, o4}, ans));
                        msg = "Question added to " + id;
                    }
                }
            }

            if ("deleteQuestion".equals(action)) {
                String id = request.getParameter("testId");
                String qid = request.getParameter("qid");
                id = id == null ? "" : id.trim().toUpperCase();
                qid = qid == null ? "" : qid.trim().toUpperCase();

                Map<String, Object> t = testIndex.get(id);
                if (t == null) {
                    err = "Target test not found.";
                } else {
                    List<Map<String, Object>> qs = (List<Map<String, Object>>) t.get("questions");
                    boolean removed = false;
                    for (Iterator<Map<String, Object>> it = qs.iterator(); it.hasNext();) {
                        Map<String, Object> q = it.next();
                        if (qid.equals(String.valueOf(q.get("id")))) {
                            it.remove();
                            removed = true;
                            break;
                        }
                    }
                    if (removed) {
                        msg = "Question removed: " + qid;
                    } else {
                        err = "Question ID not found in test.";
                    }
                }
            }

            if ("importAI".equals(action) || "generateAI".equals(action)) {
                String payload = request.getParameter("aiPayload");
                boolean replaceExisting = "on".equals(request.getParameter("replaceExisting"));
                if ("generateAI".equals(action)) {
                    String apiKey = request.getParameter("geminiApiKey");
                    if (apiKey == null || apiKey.trim().isEmpty()) {
                        apiKey = request.getParameter("openaiApiKey");
                    }
                    String topic = request.getParameter("genTopic");
                    String level = request.getParameter("genLevel");
                    String countStr = request.getParameter("genCount");
                    String genTestId = request.getParameter("genTestId");
                    String genTestName = request.getParameter("genTestName");
                    String genTagline = request.getParameter("genTagline");
                    String genDuration = request.getParameter("genDurationMin");
                    String genPass = request.getParameter("genPassPercent");

                    apiKey = apiKey == null ? "" : apiKey.trim();
                    topic = topic == null ? "" : topic.trim();
                    level = level == null ? "" : level.trim();
                    countStr = countStr == null ? "10" : countStr.trim();
                    genTestId = genTestId == null ? "" : genTestId.trim().toUpperCase();
                    genTestName = genTestName == null ? "" : genTestName.trim();
                    genTagline = genTagline == null ? "" : genTagline.trim();
                    genDuration = genDuration == null ? "20" : genDuration.trim();
                    genPass = genPass == null ? "60" : genPass.trim();

                    if (apiKey.isEmpty()) {
                        err = "Gemini API key is required for direct generation.";
                    } else if (apiKey.contains("HTTP Status") || apiKey.contains("Internal Server Error")) {
                        err = "Invalid Gemini API key value pasted. Please paste only the API key.";
                    } else if (apiKey.matches(".*\\s+.*")) {
                        err = "Invalid Gemini API key format (contains whitespace/newline).";
                    } else {
                        int qCount = 10;
                        try {
                            qCount = Integer.parseInt(countStr);
                        } catch (Exception ignore) {
                            qCount = 10;
                        }
                        if (qCount < 3) qCount = 3;
                        if (qCount > 50) qCount = 50;

                        String prompt = ""
                                + "Create a multiple-choice exam strictly in the format below.\n"
                                + "No markdown, no explanation, no extra text.\n"
                                + "Topic: " + topic + "\n"
                                + "Level: " + level + "\n"
                                + "Question count: " + qCount + "\n\n"
                                + "FORMAT:\n"
                                + "TEST_ID: " + genTestId + "\n"
                                + "TEST_NAME: " + genTestName + "\n"
                                + "TAGLINE: " + genTagline + "\n"
                                + "DURATION_MIN: " + genDuration + "\n"
                                + "PASS_PERCENT: " + genPass + "\n"
                                + "Q\\t<QUESTION_ID>\\t<QUESTION_TEXT>\\t<OPTION1>\\t<OPTION2>\\t<OPTION3>\\t<OPTION4>\\t<CORRECT_OPTION_INDEX_0_TO_3>\n\n"
                                + "Rules:\n"
                                + "- Provide exactly " + qCount + " Q lines\n"
                                + "- Use unique QUESTION_ID values\n"
                                + "- Correct index must be 0,1,2 or 3\n"
                                + "- Keep options concise and valid.";

                        String reqJson = "{"
                                + "\"contents\":[{"
                                + "\"role\":\"user\","
                                + "\"parts\":[{\"text\":\"" + jsonEscape(prompt) + "\"}]"
                                + "}],"
                                + "\"generationConfig\":{"
                                + "\"temperature\":0.4"
                                + "}"
                                + "}";

                        try {
                            HttpClient client = HttpClient.newBuilder()
                                    .connectTimeout(Duration.ofSeconds(20))
                                    .build();
                            String geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + URLEncoder.encode(apiKey, "UTF-8");
                            HttpRequest httpReq = HttpRequest.newBuilder()
                                    .uri(URI.create(geminiUrl))
                                    .header("Content-Type", "application/json")
                                    .timeout(Duration.ofSeconds(60))
                                    .POST(HttpRequest.BodyPublishers.ofString(reqJson))
                                    .build();

                            HttpResponse<String> aiResp = null;
                            for (int attempt = 0; attempt < 2; attempt++) {
                                aiResp = client.send(httpReq, HttpResponse.BodyHandlers.ofString());
                                if (aiResp.statusCode() != 429 || attempt == 1) {
                                    break;
                                }
                                try {
                                    Thread.sleep(1500);
                                } catch (InterruptedException ie) {
                                    Thread.currentThread().interrupt();
                                }
                            }

                            if (aiResp != null && aiResp.statusCode() >= 200 && aiResp.statusCode() < 300) {
                                payload = extractFirstGeminiText(aiResp.body());
                                if (payload == null || payload.trim().isEmpty()) {
                                    err = "Could not parse AI response content.";
                                } else {
                                    payload = payload.trim();
                                }
                            } else if (aiResp != null) {
                                String apiMsg = extractJsonStringField(aiResp.body(), "message");
                                if (apiMsg == null || apiMsg.trim().isEmpty()) {
                                    err = "Gemini API error: HTTP " + aiResp.statusCode();
                                } else {
                                    err = "Gemini API error: HTTP " + aiResp.statusCode() + " - " + apiMsg;
                                }
                            } else {
                                err = "Gemini API call failed: empty response.";
                            }
                        } catch (Exception ex) {
                            err = "Gemini API call failed: " + ex.getMessage();
                        }
                    }
                }

                payload = payload == null ? "" : payload.trim();
                if (err.isEmpty() && payload.isEmpty()) {
                    err = "AI payload is empty.";
                } else if (err.isEmpty()) {
                    String testId = "";
                    String testName = "";
                    String tagline = "";
                    int durationMin = 0;
                    double passPercent = 0.0;
                    List<Map<String, Object>> importedQuestions = new ArrayList<Map<String, Object>>();
                    Set<String> seenIds = new HashSet<String>();

                    String[] lines = payload.split("\\r?\\n");
                    for (int i = 0; i < lines.length; i++) {
                        String raw = lines[i];
                        String line = raw == null ? "" : raw.trim();
                        if (line.isEmpty() || line.startsWith("#")) {
                            continue;
                        }

                        if (line.startsWith("TEST_ID:")) {
                            testId = line.substring("TEST_ID:".length()).trim().toUpperCase();
                            continue;
                        }
                        if (line.startsWith("TEST_NAME:")) {
                            testName = line.substring("TEST_NAME:".length()).trim();
                            continue;
                        }
                        if (line.startsWith("TAGLINE:")) {
                            tagline = line.substring("TAGLINE:".length()).trim();
                            continue;
                        }
                        if (line.startsWith("DURATION_MIN:")) {
                            try {
                                durationMin = Integer.parseInt(line.substring("DURATION_MIN:".length()).trim());
                            } catch (Exception ex) {
                                err = "Invalid DURATION_MIN value.";
                            }
                            continue;
                        }
                        if (line.startsWith("PASS_PERCENT:")) {
                            try {
                                passPercent = Double.parseDouble(line.substring("PASS_PERCENT:".length()).trim());
                            } catch (Exception ex) {
                                err = "Invalid PASS_PERCENT value.";
                            }
                            continue;
                        }

                        if (line.startsWith("Q\t")) {
                            String[] parts = line.split("\\t", -1);
                            if (parts.length < 8) {
                                err = "Invalid question row format. Expected 8 tab-separated columns.";
                                break;
                            }
                            String qid = parts[1].trim().toUpperCase();
                            String qtext = parts[2].trim();
                            String o1 = parts[3].trim();
                            String o2 = parts[4].trim();
                            String o3 = parts[5].trim();
                            String o4 = parts[6].trim();
                            int ans = -1;
                            try {
                                ans = Integer.parseInt(parts[7].trim());
                            } catch (Exception ignore) {
                                ans = -1;
                            }

                            if (qid.isEmpty() || qtext.isEmpty() || o1.isEmpty() || o2.isEmpty() || o3.isEmpty() || o4.isEmpty() || ans < 0 || ans > 3) {
                                err = "Invalid question values found in payload.";
                                break;
                            }
                            if (seenIds.contains(qid)) {
                                err = "Duplicate question ID in payload: " + qid;
                                break;
                            }
                            seenIds.add(qid);
                            importedQuestions.add(q(qid, qtext, new String[]{o1, o2, o3, o4}, ans));
                        }
                    }

                    if (err.isEmpty()) {
                        if (testId.isEmpty() || testName.isEmpty() || durationMin <= 0 || passPercent <= 0 || passPercent > 100 || importedQuestions.isEmpty()) {
                            err = "Payload missing required fields or questions.";
                        } else {
                            Map<String, Object> existing = testIndex.get(testId);
                            if (existing != null && !replaceExisting) {
                                err = "Test ID already exists. Enable replace to overwrite.";
                            } else {
                                if (existing != null) {
                                    for (Iterator<Map<String, Object>> it = testCatalog.iterator(); it.hasNext();) {
                                        Map<String, Object> t = it.next();
                                        if (testId.equals(String.valueOf(t.get("id")))) {
                                            it.remove();
                                            break;
                                        }
                                    }
                                }
                                testCatalog.add(test(testId, testName, tagline, durationMin * 60, passPercent, importedQuestions));
                                msg = "AI test imported: " + testId + " (" + importedQuestions.size() + " questions)";
                            }
                        }
                    }
                }
            }
        }

        response.sendRedirect("admin.jsp?msg=" + URLEncoder.encode(msg, "UTF-8") + "&err=" + URLEncoder.encode(err, "UTF-8"));
        return;
    }

    String msgQ = request.getParameter("msg");
    String errQ = request.getParameter("err");
    List<String> studentUsernames = new ArrayList<String>();
    for (Map.Entry<String, Map<String, String>> e : users.entrySet()) {
        Map<String, String> u = e.getValue();
        String role = u.get("role") == null ? "student" : u.get("role");
        if (!"admin".equals(role)) {
            studentUsernames.add(e.getKey());
        }
    }
    Collections.sort(studentUsernames);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Control | Exam Grid 2050</title>
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
<div class="max-w-7xl mx-auto px-4 py-8">
    <div class="flex items-center justify-between">
        <div>
            <p class="text-xs uppercase tracking-[0.25em] text-emerald-300">Administrator</p>
            <h1 class="font-display text-3xl md:text-4xl">Test Control Panel</h1>
        </div>
        <a href="dashboard.jsp" class="px-4 py-2 rounded-xl border border-white/20 hover:bg-white/10">Dashboard</a>
    </div>

    <% if (msgQ != null && !msgQ.trim().isEmpty()) { %>
    <div class="mt-4 rounded-lg border border-emerald-400/40 bg-emerald-500/15 px-4 py-3 text-emerald-200"><%= esc(msgQ) %></div>
    <% } %>
    <% if (errQ != null && !errQ.trim().isEmpty()) { %>
    <div class="mt-4 rounded-lg border border-red-400/40 bg-red-500/15 px-4 py-3 text-red-200"><%= esc(errQ) %></div>
    <% } %>

    <section class="rounded-2xl border border-cyan-300/25 bg-cyan-500/10 p-5 mt-6">
        <h2 class="font-display text-2xl">AI Test Generator (ChatGPT)</h2>
        <p class="text-sm text-slate-300 mt-1">You can generate directly with Gemini API, or use prompt + paste mode.</p>

        <form method="post" class="grid gap-3 mt-4 rounded-xl border border-emerald-300/25 bg-emerald-500/10 p-4">
            <input type="hidden" name="action" value="generateAI">
            <h3 class="font-display text-lg text-emerald-200">Direct Generate and Import</h3>
            <input type="password" name="geminiApiKey" placeholder="Gemini API key" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
            <div class="grid md:grid-cols-3 gap-3">
                <input name="genTopic" placeholder="Topic (e.g. Internet of Things)" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <input name="genLevel" placeholder="Level (Beginner/Intermediate/Advanced)" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <input type="number" name="genCount" min="3" max="50" value="10" placeholder="Question count" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
            </div>
            <div class="grid md:grid-cols-3 gap-3">
                <input name="genTestId" placeholder="Test ID (e.g. IOTINT)" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <input name="genTestName" placeholder="Test Name" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <input name="genTagline" placeholder="Tagline" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2">
            </div>
            <div class="grid md:grid-cols-3 gap-3">
                <input type="number" name="genDurationMin" min="1" value="20" placeholder="Duration (min)" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <input type="number" step="0.1" name="genPassPercent" min="1" max="100" value="60" placeholder="Pass %" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <label class="inline-flex items-center gap-2 text-sm text-slate-200 rounded-lg border border-white/20 px-3 py-2">
                    <input type="checkbox" name="replaceExisting" class="accent-cyan-400">
                    Replace if ID exists
                </label>
            </div>
            <button class="rounded-xl py-2 bg-gradient-to-r from-emerald-400 to-cyan-400 text-slate-900 font-semibold">Generate with API and Import</button>
            <p class="text-xs text-slate-300">Security: key is used only for this request and not stored in tests/users.</p>
        </form>

        <div class="grid md:grid-cols-4 gap-3 mt-4">
            <input id="aiTopic" placeholder="Topic (e.g. Data Structures)" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2">
            <input id="aiLevel" placeholder="Level (e.g. Intermediate)" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2">
            <input id="aiCount" type="number" min="3" value="10" placeholder="Question count" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2">
            <button type="button" onclick="buildAIPrompt()" class="rounded-xl py-2 bg-gradient-to-r from-cyan-400 to-emerald-400 text-slate-900 font-semibold">Generate ChatGPT Prompt</button>
        </div>

        <textarea id="aiPromptBox" class="mt-3 w-full min-h-40 rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2 text-sm" placeholder="Prompt for ChatGPT will appear here..."></textarea>
        <div class="flex gap-3 mt-2">
            <button type="button" onclick="copyAIPrompt()" class="rounded-lg px-3 py-2 border border-cyan-300/40 text-cyan-200 hover:bg-cyan-500/20">Copy Prompt</button>
            <a href="https://chatgpt.com/" target="_blank" class="rounded-lg px-3 py-2 border border-emerald-300/40 text-emerald-200 hover:bg-emerald-500/20">Open ChatGPT</a>
        </div>

        <form method="post" class="mt-5 grid gap-3">
            <input type="hidden" name="action" value="importAI">
            <label class="text-sm text-slate-300">Paste ChatGPT output in required format:</label>
            <textarea name="aiPayload" class="w-full min-h-64 rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2 font-mono text-xs" placeholder="TEST_ID: DS01
TEST_NAME: Data Structures Core
TAGLINE: Arrays, stacks, queues and trees
DURATION_MIN: 20
PASS_PERCENT: 60
Q	DSQ1	What is the amortized complexity of dynamic array append?	O(n)	O(1) average	O(log n)	O(n log n)	1"></textarea>
            <label class="inline-flex items-center gap-2 text-sm text-slate-300">
                <input type="checkbox" name="replaceExisting" class="accent-cyan-400">
                Replace existing test if TEST_ID already exists
            </label>
            <button class="rounded-xl py-2 bg-gradient-to-r from-emerald-400 to-cyan-400 text-slate-900 font-semibold">Import AI Test</button>
        </form>
    </section>

    <div class="grid lg:grid-cols-2 gap-4 mt-6">
        <section class="rounded-2xl border border-white/15 bg-white/10 p-5">
            <h2 class="font-display text-xl">Create Test</h2>
            <form method="post" class="grid gap-3 mt-3">
                <input type="hidden" name="action" value="createTest">
                <input name="testId" placeholder="Test ID (e.g. DSA)" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <input name="testName" placeholder="Test Name" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <input name="tagline" placeholder="Tagline" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2">
                <div class="grid grid-cols-2 gap-3">
                    <input type="number" name="durationMin" min="1" placeholder="Duration (min)" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                    <input type="number" step="0.1" name="passPercent" min="1" max="100" placeholder="Pass %" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                </div>
                <button class="rounded-xl py-2 bg-gradient-to-r from-cyan-400 to-emerald-400 text-slate-900 font-semibold">Create Test</button>
            </form>
        </section>

        <section class="rounded-2xl border border-white/15 bg-white/10 p-5">
            <h2 class="font-display text-xl">Delete Test</h2>
            <form method="post" class="grid gap-3 mt-3">
                <input type="hidden" name="action" value="deleteTest">
                <input name="testId" placeholder="Test ID" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <button class="rounded-xl py-2 bg-red-500/90 hover:bg-red-500 font-semibold">Delete Test</button>
            </form>
        </section>

        <section class="rounded-2xl border border-white/15 bg-white/10 p-5 lg:col-span-2">
            <h2 class="font-display text-xl">Add Question</h2>
            <form method="post" class="grid gap-3 mt-3">
                <input type="hidden" name="action" value="addQuestion">
                <div class="grid sm:grid-cols-2 gap-3">
                    <input name="testId" placeholder="Target Test ID" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                    <input name="qid" placeholder="Question ID" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                </div>
                <textarea name="qtext" placeholder="Question text" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required></textarea>
                <div class="grid sm:grid-cols-2 gap-3">
                    <input name="o1" placeholder="Option 1" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                    <input name="o2" placeholder="Option 2" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                    <input name="o3" placeholder="Option 3" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                    <input name="o4" placeholder="Option 4" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                </div>
                <input type="number" name="answer" min="0" max="3" placeholder="Correct Option Index (0-3)" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <button class="rounded-xl py-2 bg-gradient-to-r from-cyan-400 to-emerald-400 text-slate-900 font-semibold">Add Question</button>
            </form>
        </section>

        <section class="rounded-2xl border border-white/15 bg-white/10 p-5 lg:col-span-2">
            <h2 class="font-display text-xl">Delete Question</h2>
            <form method="post" class="grid sm:grid-cols-3 gap-3 mt-3">
                <input type="hidden" name="action" value="deleteQuestion">
                <input name="testId" placeholder="Target Test ID" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <input name="qid" placeholder="Question ID" class="rounded-lg bg-slate-900/70 border border-white/20 px-3 py-2" required>
                <button class="rounded-xl py-2 bg-red-500/90 hover:bg-red-500 font-semibold">Delete Question</button>
            </form>
        </section>
    </div>

    <section class="rounded-2xl border border-white/15 bg-white/10 p-5 mt-6">
        <h2 class="font-display text-xl">Current Tests</h2>
        <div class="overflow-x-auto mt-3">
            <table class="w-full min-w-[760px] text-left">
                <thead class="text-xs uppercase tracking-[0.12em] text-slate-300">
                <tr>
                    <th class="py-2">ID</th>
                    <th class="py-2">Name</th>
                    <th class="py-2">Duration</th>
                    <th class="py-2">Pass %</th>
                    <th class="py-2">Questions</th>
                </tr>
                </thead>
                <tbody>
                <% for (Map<String, Object> t : testCatalog) {
                    List<Map<String, Object>> qs = (List<Map<String, Object>>) t.get("questions");
                %>
                <tr class="border-t border-white/10">
                    <td class="py-2 font-mono text-xs"><%= esc(String.valueOf(t.get("id"))) %></td>
                    <td class="py-2"><%= esc(String.valueOf(t.get("name"))) %></td>
                    <td class="py-2"><%= ((Number) t.get("durationSec")).intValue() / 60 %> min</td>
                    <td class="py-2"><%= String.format("%.1f", ((Number) t.get("passPercent")).doubleValue()) %></td>
                    <td class="py-2"><%= qs.size() %></td>
                </tr>
                <% } %>
                </tbody>
            </table>
        </div>
        <p class="text-slate-400 text-sm mt-3">Default admin credentials: <span class="font-mono">admin / admin123</span></p>
    </section>

    <section class="rounded-2xl border border-cyan-300/25 bg-cyan-500/10 p-5 mt-6">
        <div class="flex items-center justify-between gap-3">
            <h2 class="font-display text-2xl">Student Performance Console</h2>
            <p class="text-sm text-slate-300">Users: <%= studentUsernames.size() %></p>
        </div>

        <% if (studentUsernames.isEmpty()) { %>
        <p class="text-slate-300 mt-4">No student accounts yet.</p>
        <% } else { %>
        <div class="grid xl:grid-cols-2 gap-4 mt-4">
            <% for (String studentUsername : studentUsernames) {
                Map<String, String> student = users.get(studentUsername);
                String studentName = student.get("fullName");
                int userAttempts = 0;
                int totalScore = 0;
                int totalQuestions = 0;
                double best = 0.0;
                double avg = 0.0;
                Set<String> attemptedTestIds = new HashSet<String>();
                Map<String, Map<String, Object>> latestByTest = new HashMap<String, Map<String, Object>>();
                Map<String, Long> latestTs = new HashMap<String, Long>();

                for (Map<String, Object> at : attempts) {
                    if (studentUsername.equals(String.valueOf(at.get("username")))) {
                        userAttempts++;
                        double p = ((Number) at.get("percent")).doubleValue();
                        avg += p;
                        if (p > best) {
                            best = p;
                        }
                        totalScore += ((Number) at.get("score")).intValue();
                        totalQuestions += ((Number) at.get("total")).intValue();

                        String testId = String.valueOf(at.get("testId"));
                        attemptedTestIds.add(testId);
                        Long endTs = (Long) at.get("endTs");
                        Long prev = latestTs.get(testId);
                        if (prev == null || endTs.longValue() >= prev.longValue()) {
                            latestTs.put(testId, endTs);
                            latestByTest.put(testId, at);
                        }
                    }
                }
                if (userAttempts > 0) {
                    avg = avg / userAttempts;
                }
                double overall = totalQuestions == 0 ? 0.0 : (totalScore * 100.0 / totalQuestions);
                int completed = attemptedTestIds.size();

                List<Map<String, Object>> orderedUserTests = new ArrayList<Map<String, Object>>();
                for (Map<String, Object> t : testCatalog) {
                    String tid = String.valueOf(t.get("id"));
                    if (!attemptedTestIds.contains(tid)) {
                        orderedUserTests.add(t);
                    }
                }
                for (Map<String, Object> t : testCatalog) {
                    String tid = String.valueOf(t.get("id"));
                    if (attemptedTestIds.contains(tid)) {
                        orderedUserTests.add(t);
                    }
                }
            %>
            <article class="rounded-2xl border border-white/15 bg-white/10 backdrop-blur-md p-4">
                <div class="flex items-center justify-between gap-3">
                    <div>
                        <p class="font-display text-xl"><%= esc(studentName) %></p>
                        <p class="text-xs text-slate-300 font-mono"><%= esc(studentUsername) %></p>
                    </div>
                    <span class="text-xs uppercase tracking-[0.2em] px-2 py-1 rounded-full border border-cyan-300/40 bg-cyan-500/15 text-cyan-200"><%= completed %>/<%= testCatalog.size() %> tracks</span>
                </div>

                <div class="grid grid-cols-4 gap-2 mt-4 text-center">
                    <div class="rounded-lg border border-white/10 bg-slate-900/45 p-2">
                        <p class="text-[11px] text-slate-400">Attempts</p>
                        <p class="font-semibold"><%= userAttempts %></p>
                    </div>
                    <div class="rounded-lg border border-white/10 bg-slate-900/45 p-2">
                        <p class="text-[11px] text-slate-400">Overall</p>
                        <p class="font-semibold"><%= String.format("%.1f", overall) %>%</p>
                    </div>
                    <div class="rounded-lg border border-white/10 bg-slate-900/45 p-2">
                        <p class="text-[11px] text-slate-400">Best</p>
                        <p class="font-semibold"><%= String.format("%.1f", best) %>%</p>
                    </div>
                    <div class="rounded-lg border border-white/10 bg-slate-900/45 p-2">
                        <p class="text-[11px] text-slate-400">Average</p>
                        <p class="font-semibold"><%= String.format("%.1f", avg) %>%</p>
                    </div>
                </div>

                <p class="text-xs uppercase tracking-[0.2em] text-slate-300 mt-4">Track Queue (Unattempted first)</p>
                <div class="grid gap-2 mt-2">
                    <% for (Map<String, Object> t : orderedUserTests) {
                        String tid = String.valueOf(t.get("id"));
                        boolean attempted = attemptedTestIds.contains(tid);
                        Map<String, Object> latest = latestByTest.get(tid);
                    %>
                    <div class="rounded-lg border border-white/10 bg-slate-900/35 p-2 flex items-center justify-between gap-2">
                        <div>
                            <p class="text-sm font-semibold"><%= esc(String.valueOf(t.get("name"))) %></p>
                            <p class="text-[11px] text-slate-400 font-mono"><%= esc(tid) %></p>
                        </div>
                        <% if (attempted) { %>
                        <span class="text-[10px] uppercase tracking-[0.2em] px-2 py-1 rounded-full border border-emerald-300/40 bg-emerald-500/15 text-emerald-200">Attempted <%= String.format("%.1f", ((Number) latest.get("percent")).doubleValue()) %>%</span>
                        <% } else { %>
                        <span class="text-[10px] uppercase tracking-[0.2em] px-2 py-1 rounded-full border border-amber-300/40 bg-amber-500/15 text-amber-200">Unattempted</span>
                        <% } %>
                    </div>
                    <% } %>
                </div>
            </article>
            <% } %>
        </div>
        <% } %>
    </section>
</div>
<script>
    function buildAIPrompt() {
        const topic = (document.getElementById('aiTopic').value || 'Computer Science').trim();
        const level = (document.getElementById('aiLevel').value || 'Intermediate').trim();
        const count = (document.getElementById('aiCount').value || '10').trim();
        const testId = topic.replace(/[^A-Za-z0-9]/g, '').toUpperCase().substring(0, 6) || 'AITEST';
        const lines = [
            'Create a multiple-choice exam strictly in the format below.',
            'No markdown, no explanation, no extra text.',
            'Topic: ' + topic,
            'Level: ' + level,
            'Question count: ' + count,
            '',
            'FORMAT (tab-separated for question rows):',
            'TEST_ID: ' + testId,
            'TEST_NAME: <name>',
            'TAGLINE: <short tagline>',
            'DURATION_MIN: <integer>',
            'PASS_PERCENT: <number 1-100>',
            'Q\\t<QUESTION_ID>\\t<QUESTION_TEXT>\\t<OPTION1>\\t<OPTION2>\\t<OPTION3>\\t<OPTION4>\\t<CORRECT_OPTION_INDEX_0_TO_3>',
            '',
            'Rules:',
            '- Provide exactly ' + count + ' Q lines',
            '- Use unique QUESTION_ID values',
            '- Correct index must be 0,1,2 or 3',
            '- Keep options concise and unambiguous'
        ];
        document.getElementById('aiPromptBox').value = lines.join('\n');
    }

    function copyAIPrompt() {
        const box = document.getElementById('aiPromptBox');
        box.select();
        document.execCommand('copy');
    }
</script>
</body>
</html>
