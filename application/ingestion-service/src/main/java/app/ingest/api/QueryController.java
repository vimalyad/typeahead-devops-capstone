package app.ingest.api;

import app.ingest.api.QueryRepository.QueryItem;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.net.URI;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

/** Query management for the temporary classroom deployment; it is not a public admin service. */
@RestController
@RequestMapping("/api/queries")
public class QueryController {
    public record QueryInput(
            @NotBlank @Size(max = 200) String query,
            @Min(0) @Max(1_000_000) long allTimeCount) {}

    private final QueryRepository repository;

    public QueryController(QueryRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<QueryItem> list() {
        return repository.list();
    }

    @GetMapping("/{id}")
    public QueryItem get(@PathVariable long id) {
        return repository.find(id);
    }

    @PostMapping
    public ResponseEntity<QueryItem> create(@Valid @RequestBody QueryInput input) {
        QueryItem item = repository.create(normalize(input.query()), input.allTimeCount());
        return ResponseEntity.created(URI.create("/api/queries/" + item.id())).body(item);
    }

    @PutMapping("/{id}")
    public QueryItem update(@PathVariable long id, @Valid @RequestBody QueryInput input) {
        return repository.update(id, normalize(input.query()), input.allTimeCount());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable long id) {
        if (!repository.delete(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Query not found");
        }
    }

    @ExceptionHandler(EmptyResultDataAccessException.class)
    public ResponseEntity<Map<String, String>> missing() {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "Query not found"));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, String>> conflict() {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("message", "Query already exists"));
    }

    private static String normalize(String query) {
        return query.strip().toLowerCase(Locale.ROOT);
    }
}
