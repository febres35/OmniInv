from app.schemas import PaginatedPerPageRequest


def get_sorting_from_request(
    sorting: PaginatedPerPageRequest,
    def_col_id,
    list_cols,
    desc=True
) -> list:

    sorting_states = sorting.sorting

    if sorting_states is None or len(sorting_states) == 0:
        sorting_states = f"{str(def_col_id)}:{'desc' if desc else 'asc'}"

    sorted_columns = []
    for _ in sorting_states.split(','):

        try:
            id, state_desc = sorting_states.split(":")
            selected_col = list_cols[id]

        except Exception as ex:
            raise ex

        if state_desc == 'desc':
            sorted_columns.append(selected_col.desc())
        else:
            sorted_columns.append(selected_col.asc())

    return sorted_columns
