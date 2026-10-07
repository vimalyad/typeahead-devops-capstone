import { useEffect, useState, type FormEvent } from "react";
import { listQueries, removeQuery, saveQuery, type QueryItem } from "../api";

export function QueryManager() {
  const [items, setItems] = useState<QueryItem[]>([]);
  const [query, setQuery] = useState("");
  const [count, setCount] = useState(0);
  const [editing, setEditing] = useState<number>();
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    listQueries().then((rows) => { if (active) setItems(rows); })
      .catch((cause: Error) => { if (active) setError(cause.message); });
    return () => { active = false; };
  }, []);

  function reset() {
    setEditing(undefined);
    setQuery("");
    setCount(0);
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError("");
    setMessage("");
    try {
      await saveQuery(query, count, editing);
      setItems(await listQueries());
      setMessage(editing === undefined ? "Query added." : "Query updated.");
      reset();
    } catch (cause) {
      setError((cause as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function remove(item: QueryItem) {
    setBusy(true);
    setError("");
    setMessage("");
    try {
      await removeQuery(item.id);
      setItems(await listQueries());
      if (editing === item.id) reset();
      setMessage(`Deleted “${item.query}”.`);
    } catch (cause) {
      setError((cause as Error).message);
    } finally {
      setBusy(false);
    }
  }

  const button = "rounded-lg border border-black/10 px-3 py-2 text-sm disabled:opacity-40 hover:border-accent-ring";
  return (
    <section className="mt-12 border-t border-black/10 pt-7" aria-labelledby="catalog-title">
      <h2 id="catalog-title" className="text-lg font-semibold text-ink">Query catalog</h2>
      <p className="mt-1 text-sm text-ink-soft">Manage the terms used for suggestions. Search results refresh within a few seconds.</p>
      <form onSubmit={(event) => void submit(event)} className="mt-5 flex flex-wrap items-end gap-3">
        <label className="min-w-48 flex-1 text-sm text-ink-soft">
          Query text
          <input className="mt-1 w-full rounded-lg border border-black/10 bg-surface-raised p-2 text-ink"
            required maxLength={200} value={query} onChange={(event) => setQuery(event.target.value)} />
        </label>
        <label className="w-28 text-sm text-ink-soft">
          Search count
          <input className="mt-1 w-full rounded-lg border border-black/10 bg-surface-raised p-2 text-ink"
            type="number" required min={0} max={1000000} step={1} value={count}
            onChange={(event) => setCount(Number(event.target.value))} />
        </label>
        <button className={button} type="submit" disabled={busy || !query.trim()}>
          {editing === undefined ? "Add query" : "Save changes"}
        </button>
        {editing !== undefined && <button className={button} type="button" onClick={reset}>Cancel</button>}
      </form>
      <p role="status" className="mt-3 min-h-6 text-sm text-ink-soft">{message}</p>
      {error && <p role="alert" className="text-sm text-red-700">{error}</p>}
      <ul className="mt-3 divide-y divide-black/5">
        {items.map((item) => <li key={item.id} className="flex flex-wrap items-center gap-3 py-3">
          <span className="min-w-40 flex-1 break-words text-sm text-ink">{item.query}</span>
          <span className="text-xs text-ink-soft">{item.allTimeCount} searches</span>
          <button type="button" className={button} disabled={busy} aria-label={`Edit ${item.query}`}
            onClick={() => { setEditing(item.id); setQuery(item.query); setCount(item.allTimeCount); }}>Edit</button>
          <button type="button" className={button} disabled={busy} aria-label={`Delete ${item.query}`}
            onClick={() => void remove(item)}>Delete</button>
        </li>)}
      </ul>
      {items.length === 0 && !error && <p className="text-sm text-ink-soft">Add the first query to get started.</p>}
    </section>
  );
}
