<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*, java.net.*, java.nio.charset.StandardCharsets, jakarta.servlet.http.Cookie" %>
<%
    request.setCharacterEncoding("UTF-8");
    String action = request.getParameter("action");
    if (action == null) {
        action = "";
    }

    String status = "Ready";

    if ("setCookie".equals(action)) {
        String cookieName = request.getParameter("cookieName");
        String cookieValue = request.getParameter("cookieValue");
        String maxAgeStr = request.getParameter("cookieMaxAge");

        if (cookieName != null && !cookieName.trim().isEmpty()) {
            int maxAge = 3600;
            try {
                if (maxAgeStr != null && !maxAgeStr.trim().isEmpty()) {
                    maxAge = Integer.parseInt(maxAgeStr.trim());
                }
            } catch (NumberFormatException ignore) {
                maxAge = 3600;
            }

            String encodedValue = URLEncoder.encode(cookieValue == null ? "" : cookieValue, StandardCharsets.UTF_8);
            try {
                Cookie cookie = new Cookie(cookieName.trim(), encodedValue);
                cookie.setMaxAge(maxAge);
                cookie.setPath(request.getContextPath().isEmpty() ? "/" : request.getContextPath());
                response.addCookie(cookie);
                status = "Cookie set: " + cookieName + " (maxAge=" + maxAge + "s)";
            } catch (IllegalArgumentException ex) {
                status = "Invalid cookie: " + ex.getMessage();
            }
        } else {
            status = "Cookie name is required.";
        }
    } else if ("deleteCookie".equals(action)) {
        String cookieName = request.getParameter("cookieName");
        if (cookieName != null && !cookieName.trim().isEmpty()) {
            Cookie cookie = new Cookie(cookieName.trim(), "");
            cookie.setMaxAge(0);
            cookie.setPath(request.getContextPath().isEmpty() ? "/" : request.getContextPath());
            response.addCookie(cookie);
            status = "Cookie deleted: " + cookieName;
        } else {
            status = "Cookie name is required to delete.";
        }
    } else if ("setSession".equals(action)) {
        String sessionKey = request.getParameter("sessionKey");
        String sessionValue = request.getParameter("sessionValue");
        if (sessionKey != null && !sessionKey.trim().isEmpty()) {
            session.setAttribute(sessionKey.trim(), sessionValue == null ? "" : sessionValue);
            status = "Session attribute set: " + sessionKey;
        } else {
            status = "Session key is required.";
        }
    } else if ("removeSession".equals(action)) {
        String sessionKey = request.getParameter("sessionKey");
        if (sessionKey != null && !sessionKey.trim().isEmpty()) {
            session.removeAttribute(sessionKey.trim());
            status = "Session attribute removed: " + sessionKey;
        } else {
            status = "Session key is required to remove.";
        }
    } else if ("invalidateSession".equals(action)) {
        session.invalidate();
        HttpSession newSession = request.getSession(true);
        status = "Session invalidated. New session ID: " + newSession.getId();
    }

    String statusJs = status == null ? "" : status
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\r", "\\r")
            .replace("\n", "\\n")
            .replace("</", "<\\/");

    Cookie[] cookies = request.getCookies();
    List<Cookie> cookieList = new ArrayList<Cookie>();
    if (cookies != null) {
        cookieList = Arrays.asList(cookies);
    }

    List<String> sessionKeys = new ArrayList<String>();
    Enumeration<String> names = session.getAttributeNames();
    while (names.hasMoreElements()) {
        sessionKeys.add(names.nextElement());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JSP Cookies & Session Playground</title>
    <style>
        :root {
            --bg: #f3f8ff;
            --panel: #ffffff;
            --ink: #102a43;
            --muted: #486581;
            --brand: #0f8b8d;
            --brand-dark: #0b6470;
            --accent: #f0b429;
            --danger: #d64545;
            --line: #d9e2ec;
            --ok: #1f9d55;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: "Segoe UI", "Trebuchet MS", sans-serif;
            color: var(--ink);
            background:
                radial-gradient(circle at 20% 0%, #c7eff0 0%, transparent 35%),
                radial-gradient(circle at 90% 20%, #fff0cf 0%, transparent 30%),
                var(--bg);
            min-height: 100vh;
            padding: 28px 14px;
        }

        .container {
            max-width: 1100px;
            margin: 0 auto;
            display: grid;
            gap: 16px;
        }

        .card {
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 16px;
            box-shadow: 0 10px 26px rgba(16, 42, 67, 0.08);
        }

        h1 {
            margin: 0 0 8px;
            font-size: 1.75rem;
        }

        h2 {
            margin: 0 0 10px;
            font-size: 1.05rem;
            color: var(--brand-dark);
        }

        p { margin: 6px 0; color: var(--muted); }

        .status {
            border-left: 4px solid var(--ok);
            padding: 10px 12px;
            background: #effcf4;
            border-radius: 8px;
            font-weight: 600;
            color: #1a7f43;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 16px;
        }

        form {
            display: grid;
            gap: 10px;
            margin-bottom: 12px;
            padding: 12px;
            border: 1px solid var(--line);
            border-radius: 10px;
            background: #fbfdff;
        }

        label { font-size: 0.92rem; font-weight: 600; }

        input {
            width: 100%;
            border: 1px solid #bcccdc;
            border-radius: 8px;
            padding: 9px 10px;
            font-size: 0.95rem;
        }

        .btn-row {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-top: 4px;
        }

        button {
            border: 0;
            border-radius: 8px;
            padding: 9px 12px;
            font-weight: 700;
            cursor: pointer;
            color: #fff;
            background: var(--brand);
        }

        button.secondary { background: #627d98; }
        button.warn { background: var(--danger); }
        button:hover { opacity: 0.95; }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.92rem;
        }

        th, td {
            border: 1px solid var(--line);
            padding: 8px;
            text-align: left;
            vertical-align: top;
        }

        th {
            background: #f0f4f8;
            color: var(--brand-dark);
        }

        code {
            background: #f0f4f8;
            border-radius: 5px;
            padding: 2px 5px;
        }

        .meta {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-top: 6px;
            font-size: 0.9rem;
        }

        .pill {
            background: #e6f7fb;
            border: 1px solid #9bd6df;
            border-radius: 999px;
            padding: 6px 10px;
            color: #0b6470;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <h1>JSP Cookies + Session Playground</h1>
            <p>Use this page to set, remove, and inspect cookies and session attributes in one place.</p>
            <div class="status"><%= status %></div>
            <div class="meta">
                <span class="pill">Session ID: <code><%= session.getId() %></code></span>
                <span class="pill">Context Path: <code><%= request.getContextPath().isEmpty() ? "/" : request.getContextPath() %></code></span>
                <span class="pill">Current Time: <code><%= new java.util.Date() %></code></span>
            </div>
        </div>

        <div class="grid">
            <div class="card">
                <h2>Cookie Actions</h2>
                <form method="post">
                    <input type="hidden" name="action" value="setCookie" />
                    <div>
                        <label for="cookieName">Cookie Name</label>
                        <input id="cookieName" name="cookieName" placeholder="exampleCookie" required />
                    </div>
                    <div>
                        <label for="cookieValue">Cookie Value</label>
                        <input id="cookieValue" name="cookieValue" placeholder="hello-cookie" />
                    </div>
                    <div>
                        <label for="cookieMaxAge">Max Age (seconds)</label>
                        <input id="cookieMaxAge" name="cookieMaxAge" value="3600" type="number" min="0" />
                    </div>
                    <div class="btn-row">
                        <button type="submit">Set Cookie</button>
                    </div>
                </form>

                <form method="post">
                    <input type="hidden" name="action" value="deleteCookie" />
                    <div>
                        <label for="deleteCookieName">Cookie Name to Delete</label>
                        <input id="deleteCookieName" name="cookieName" placeholder="exampleCookie" required />
                    </div>
                    <div class="btn-row">
                        <button class="warn" type="submit">Delete Cookie</button>
                    </div>
                </form>
            </div>

            <div class="card">
                <h2>Session Actions</h2>
                <form method="post">
                    <input type="hidden" name="action" value="setSession" />
                    <div>
                        <label for="sessionKey">Session Key</label>
                        <input id="sessionKey" name="sessionKey" placeholder="username" required />
                    </div>
                    <div>
                        <label for="sessionValue">Session Value</label>
                        <input id="sessionValue" name="sessionValue" placeholder="Rohit" />
                    </div>
                    <div class="btn-row">
                        <button type="submit">Set Session Value</button>
                    </div>
                </form>

                <form method="post">
                    <input type="hidden" name="action" value="removeSession" />
                    <div>
                        <label for="removeSessionKey">Session Key to Remove</label>
                        <input id="removeSessionKey" name="sessionKey" placeholder="username" required />
                    </div>
                    <div class="btn-row">
                        <button class="secondary" type="submit">Remove Session Key</button>
                    </div>
                </form>

                <form method="post">
                    <input type="hidden" name="action" value="invalidateSession" />
                    <div class="btn-row">
                        <button class="warn" type="submit">Invalidate Session</button>
                    </div>
                </form>
            </div>
        </div>

        <div class="grid">
            <div class="card">
                <h2>Current Cookies (Server Side)</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Value</th>
                            <th>Path</th>
                            <th>Max Age</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        if (cookieList.isEmpty()) {
                    %>
                        <tr><td colspan="4">No cookies found for this request.</td></tr>
                    <%
                        } else {
                            for (Cookie c : cookieList) {
                    %>
                        <tr>
                            <td><%= c.getName() %></td>
                            <td><%
                                String decodedValue = c.getValue();
                                try {
                                    decodedValue = URLDecoder.decode(c.getValue(), StandardCharsets.UTF_8);
                                } catch (IllegalArgumentException ignore) {
                                    decodedValue = c.getValue();
                                }
                                out.print(decodedValue);
                            %></td>
                            <td><%= c.getPath() == null ? "(not set)" : c.getPath() %></td>
                            <td><%= c.getMaxAge() %></td>
                        </tr>
                    <%
                            }
                        }
                    %>
                    </tbody>
                </table>
            </div>

            <div class="card">
                <h2>Current Session Attributes</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Key</th>
                            <th>Value</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        if (sessionKeys.isEmpty()) {
                    %>
                        <tr><td colspan="2">No session attributes set.</td></tr>
                    <%
                        } else {
                            for (String key : sessionKeys) {
                    %>
                        <tr>
                            <td><%= key %></td>
                            <td><%= String.valueOf(session.getAttribute(key)) %></td>
                        </tr>
                    <%
                            }
                        }
                    %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        (function () {
            const cookieDump = document.cookie || "(no client-side cookies visible)";
            const sessionId = "<%= session.getId() %>";
            const statusText = "<%= statusJs %>";

            console.group("JSP Playground Debug");
            console.log("Status:", statusText);
            console.log("Session ID:", sessionId);
            console.log("document.cookie:", cookieDump);
            console.log("Request method:", "<%= request.getMethod() %>");
            console.groupEnd();
        })();
    </script>
</body>
</html>
