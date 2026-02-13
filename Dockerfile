# Use Tomcat with Java 17 for JSP support
FROM tomcat:10.1.52-jdk17-temurin

# Remove default ROOT app
RUN rm -rf /usr/local/tomcat/webapps/ROOT/*

# Copy JSP app files into ROOT context
COPY *.jsp /usr/local/tomcat/webapps/ROOT/
COPY *.jspf /usr/local/tomcat/webapps/ROOT/

EXPOSE 8080

CMD ["catalina.sh", "run"]
