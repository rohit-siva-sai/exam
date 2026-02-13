<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="exam-common.jspf" %>
<%
    if (!isLoggedIn(session)) {
        response.sendRedirect("login.jsp");
        return;
    }

    String activeAttemptId = (String) session.getAttribute("examAttemptId");
    Long startTs = (Long) session.getAttribute("examStartTs");
    Integer examDuration = (Integer) session.getAttribute("examDurationSec");
    String examTestId = (String) session.getAttribute("examTestId");
    Double passPercent = (Double) session.getAttribute("examPassPercent");

    if (activeAttemptId == null || startTs == null || examDuration == null || examTestId == null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    String postedAttemptId = request.getParameter("attemptId");
    if (postedAttemptId == null || !postedAttemptId.equals(activeAttemptId)) {
        response.sendRedirect("take-exam.jsp?test=" + URLEncoder.encode(examTestId, "UTF-8"));
        return;
    }

    Map<String, Object> examTest = testIndex.get(examTestId);
    if (examTest == null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    List<Map<String, Object>> questions = (List<Map<String, Object>>) examTest.get("questions");

    Map<String, Integer> answers = new HashMap<String, Integer>();
    List<Map<String, Object>> review = new ArrayList<Map<String, Object>>();

    int score = 0;
    int total = questions.size();

    for (Map<String, Object> q : questions) {
        String qid = String.valueOf(q.get("id"));
        String selected = request.getParameter(qid);
        int selectedIndex = -1;
        try {
            if (selected != null) {
                selectedIndex = Integer.parseInt(selected);
            }
        } catch (NumberFormatException ignore) {
            selectedIndex = -1;
        }
        answers.put(qid, selectedIndex);

        int correct = (Integer) q.get("answer");
        boolean isCorrect = (selectedIndex == correct);
        if (isCorrect) {
            score++;
        }

        Map<String, Object> row = new HashMap<String, Object>();
        row.put("qid", qid);
        row.put("question", q.get("text"));
        row.put("options", q.get("options"));
        row.put("selected", selectedIndex);
        row.put("correct", correct);
        row.put("isCorrect", isCorrect);
        review.add(row);
    }

    long submittedAt = System.currentTimeMillis();
    long allowedEnd = startTs + (examDuration * 1000L);
    if (submittedAt > allowedEnd) {
        submittedAt = allowedEnd;
    }

    double percent = total == 0 ? 0.0 : (score * 100.0 / total);
    double threshold = passPercent == null ? ((Number) examTest.get("passPercent")).doubleValue() : passPercent.doubleValue();
    boolean passed = percent >= threshold;

    Map<String, Object> attempt = new HashMap<String, Object>();
    attempt.put("attemptId", activeAttemptId);
    attempt.put("username", currentUser(session));
    attempt.put("fullName", session.getAttribute("authName"));
    attempt.put("testId", examTestId);
    attempt.put("testName", String.valueOf(examTest.get("name")));
    attempt.put("passPercent", threshold);
    attempt.put("durationSec", examDuration);
    attempt.put("score", score);
    attempt.put("total", total);
    attempt.put("percent", percent);
    attempt.put("passed", passed);
    attempt.put("startTs", startTs);
    attempt.put("endTs", submittedAt);
    attempt.put("answers", answers);
    attempt.put("review", review);
    attempts.add(attempt);

    session.removeAttribute("examStartTs");
    session.removeAttribute("examDurationSec");
    session.removeAttribute("examAttemptId");
    session.removeAttribute("examTestId");
    session.removeAttribute("examPassPercent");

    response.sendRedirect("result.jsp?attemptId=" + URLEncoder.encode(activeAttemptId, "UTF-8"));
%>
