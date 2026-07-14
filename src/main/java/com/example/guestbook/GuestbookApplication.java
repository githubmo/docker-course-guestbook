package com.example.guestbook;

import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.util.HtmlUtils;

// ponytail: whole app is one file. It's a demo, not a system. Split when it grows a second concern.
@SpringBootApplication
@Controller
public class GuestbookApplication {

    private static final DateTimeFormatter WHEN = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private final JdbcClient db;

    public GuestbookApplication(JdbcClient db) {
        this.db = db;
    }

    public static void main(String[] args) {
        SpringApplication.run(GuestbookApplication.class, args);
    }

    record Entry(String name, String message, OffsetDateTime createdAt) {}

    @GetMapping("/")
    @ResponseBody
    String home() {
        List<Entry> entries = db.sql(
                "SELECT name, message, created_at FROM guestbook ORDER BY created_at DESC LIMIT 50")
                .query(Entry.class).list();

        StringBuilder rows = new StringBuilder();
        for (Entry e : entries) {
            rows.append("<li><b>").append(esc(e.name())).append("</b> ")
                .append("<span class=when>").append(e.createdAt().format(WHEN)).append("</span>")
                .append("<br>").append(esc(e.message())).append("</li>");
        }
        if (entries.isEmpty()) {
            rows.append("<li class=empty>No messages yet. Be the first.</li>");
        }

        String host = System.getenv().getOrDefault("HOSTNAME", "unknown");
        return """
            <!doctype html><html><head><meta charset=utf-8>
            <title>Docker Course Guestbook</title>
            <style>
              body{font-family:system-ui,sans-serif;max-width:640px;margin:40px auto;padding:0 16px;color:#1a1a2e}
              h1{margin-bottom:4px}
              form{display:flex;gap:8px;flex-wrap:wrap;margin:20px 0}
              input,textarea{padding:8px;border:1px solid #ccc;border-radius:6px;font:inherit}
              input[name=name]{flex:0 0 140px}
              textarea{flex:1 1 100%;min-height:60px}
              button{padding:8px 16px;border:0;border-radius:6px;background:#2496ed;color:#fff;font:inherit;cursor:pointer}
              ul{list-style:none;padding:0}
              li{padding:10px 0;border-bottom:1px solid #eee}
              .when{color:#888;font-size:.8em}
              .empty{color:#888}
              footer{margin-top:30px;color:#888;font-size:.8em}
            </style></head><body>
            <h1>Guestbook</h1>
            <p>A tiny Spring Boot app writing to PostgreSQL. Add a message, then restart the app container: it survives.</p>
            <form method=post action=/messages>
              <input name=name placeholder=Name required maxlength=60>
              <textarea name=message placeholder="Your message" required maxlength=500></textarea>
              <button type=submit>Sign</button>
            </form>
            <ul>{{rows}}</ul>
            <footer>Served by container <code>{{host}}</code> &middot; data lives in Postgres, not in this container.</footer>
            </body></html>
            """
            .replace("{{rows}}", rows.toString())
            .replace("{{host}}", esc(host));
    }

    @PostMapping("/messages")
    String add(@RequestParam String name, @RequestParam String message) {
        db.sql("INSERT INTO guestbook(name, message) VALUES (?, ?)")
          .params(name, message).update();
        return "redirect:/";
    }

    private static String esc(String s) {
        return HtmlUtils.htmlEscape(s);
    }
}
