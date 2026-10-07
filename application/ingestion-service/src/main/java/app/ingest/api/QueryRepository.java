package app.ingest.api;

import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

@Repository
public class QueryRepository {
    public record QueryItem(long id, String query, long allTimeCount) {}

    private static final RowMapper<QueryItem> ROW = (rs, row) ->
            new QueryItem(rs.getLong("id"), rs.getString("query"), rs.getLong("all_time_count"));
    private final JdbcTemplate jdbc;

    public QueryRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<QueryItem> list() {
        return jdbc.query("SELECT id, query, all_time_count FROM queries ORDER BY id LIMIT 100", ROW);
    }

    public QueryItem find(long id) {
        return jdbc.queryForObject("SELECT id, query, all_time_count FROM queries WHERE id = ?", ROW, id);
    }

    public QueryItem create(String query, long count) {
        return jdbc.queryForObject("""
                INSERT INTO queries(query, all_time_count) VALUES (?, ?)
                RETURNING id, query, all_time_count
                """, ROW, query, count);
    }

    public QueryItem update(long id, String query, long count) {
        return jdbc.queryForObject("""
                UPDATE queries SET query = ?, all_time_count = ?, recent_score = 0,
                    last_updated = now() WHERE id = ? RETURNING id, query, all_time_count
                """, ROW, query, count, id);
    }

    public boolean delete(long id) {
        return jdbc.update("DELETE FROM queries WHERE id = ?", id) == 1;
    }
}
