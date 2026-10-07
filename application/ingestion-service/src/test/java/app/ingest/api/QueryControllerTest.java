package app.ingest.api;

import app.ingest.api.QueryRepository.QueryItem;
import app.ingest.kafka.SearchEventProducer;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** MVC tests use mocked persistence and Kafka; no production database or broker is contacted. */
@WebMvcTest({QueryController.class, SearchController.class})
class QueryControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean QueryRepository repository;
    @MockitoBean SearchEventProducer producer;
    private final QueryItem item = new QueryItem(7, "kubernetes", 5);

    @Test void listsQueries() throws Exception {
        when(repository.list()).thenReturn(List.of(item));
        mvc.perform(get("/api/queries")).andExpect(status().isOk())
                .andExpect(jsonPath("$[0].query").value("kubernetes"));
    }

    @Test void readsOneQuery() throws Exception {
        when(repository.find(7)).thenReturn(item);
        mvc.perform(get("/api/queries/7")).andExpect(status().isOk())
                .andExpect(jsonPath("$.allTimeCount").value(5));
    }

    @Test void reportsMissingQuery() throws Exception {
        when(repository.find(9)).thenThrow(new EmptyResultDataAccessException(1));
        mvc.perform(get("/api/queries/9")).andExpect(status().isNotFound());
    }

    @Test void createsNormalizedQuery() throws Exception {
        when(repository.create("kubernetes", 5)).thenReturn(item);
        mvc.perform(post("/api/queries").contentType("application/json")
                .content("{\"query\":\"  Kubernetes  \",\"allTimeCount\":5}"))
                .andExpect(status().isCreated()).andExpect(header().string("Location", "/api/queries/7"));
        verify(repository).create("kubernetes", 5);
    }

    @Test void rejectsBlankQuery() throws Exception {
        mvc.perform(post("/api/queries").contentType("application/json")
                .content("{\"query\":\"   \",\"allTimeCount\":1}"))
                .andExpect(status().isBadRequest());
        verifyNoInteractions(repository);
    }

    @Test void rejectsNegativeCount() throws Exception {
        mvc.perform(post("/api/queries").contentType("application/json")
                .content("{\"query\":\"terraform\",\"allTimeCount\":-1}"))
                .andExpect(status().isBadRequest());
        verifyNoInteractions(repository);
    }

    @Test void reportsDuplicateQueryWithoutSqlDetails() throws Exception {
        when(repository.create("kubernetes", 5)).thenThrow(new DuplicateKeyException("private database detail"));
        mvc.perform(post("/api/queries").contentType("application/json")
                .content("{\"query\":\"kubernetes\",\"allTimeCount\":5}"))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.message").value("Query already exists"));
    }

    @Test void updatesQuery() throws Exception {
        when(repository.update(7, "helm", 2)).thenReturn(new QueryItem(7, "helm", 2));
        mvc.perform(put("/api/queries/7").contentType("application/json")
                .content("{\"query\":\"Helm\",\"allTimeCount\":2}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.query").value("helm"));
    }

    @Test void deletesExistingQuery() throws Exception {
        when(repository.delete(7)).thenReturn(true);
        mvc.perform(delete("/api/queries/7")).andExpect(status().isNoContent());
    }

    @Test void deletingMissingQueryReturnsNotFound() throws Exception {
        mvc.perform(delete("/api/queries/99")).andExpect(status().isNotFound());
    }

    @Test void searchPublishesNormalizedEvent() throws Exception {
        mvc.perform(post("/api/search").contentType("application/json").content("{\"query\":\" Docker \"}"))
                .andExpect(status().isOk());
        verify(producer).publish("docker");
    }

    @Test void blankSearchDoesNotPublish() throws Exception {
        mvc.perform(post("/api/search").contentType("application/json").content("{\"query\":\" \"}"))
                .andExpect(status().isBadRequest());
        verifyNoInteractions(producer);
    }
}
