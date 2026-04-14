import streamlit as st
import pandas as pd
import io
import analyzer  # Ensure analyzer.py is in the same folder

st.set_page_config(page_title="PPC Intelligence Tool", layout="wide")

# Sidebar for brand keywords
st.sidebar.header("Categorization Settings")
brand_input = st.sidebar.text_area("Brand Keywords (comma separated)", "ooze, creation lamis, scion, maison")
brand_list = [b.strip().lower() for b in brand_input.replace('\n', ',').split(',') if b.strip()]

st.title("📊 Global PPC Search Term Analyzer")
st.markdown("Designed for **India (14-day)** and **UAE (7-day)** Amazon reports.")

uploaded_files = st.file_uploader("Upload Search Term Reports (.xlsx or .csv)", type=["xlsx", "csv"], accept_multiple_files=True)

if uploaded_files:
    try:
        raw_dfs_for_summary = []
        master_tabs = {}

        for file in uploaded_files:
            if file.name.endswith('.xlsx'):
                sheets = pd.read_excel(file, sheet_name=None)
                for sheet_name, df in sheets.items():
                    # Clean all tab headers for the final export
                    df = analyzer.clean_headers(df)
                    master_tabs[f"{file.name}_{sheet_name}"] = df
                    if any('Search Term' in str(c) for c in df.columns):
                        raw_dfs_for_summary.append(df)
            else:
                df = pd.read_csv(file)
                df = analyzer.clean_headers(df)
                master_tabs[file.name] = df
                raw_dfs_for_summary.append(df)

        if raw_dfs_for_summary:
            with st.spinner("Analyzing intent and calculating metrics..."):
                final_df = analyzer.standardize_and_group(raw_dfs_for_summary, brand_list)
                
                # --- KPI Metrics Bar ---
                st.subheader("Account Performance Overview")
                m1, m2, m3, m4 = st.columns(4)
                m1.metric("Total Spend", f"{final_df['Spend'].sum():,.2f}")
                m2.metric("Total Sales", f"{final_df['Sales'].sum():,.2f}")
                m3.metric("Total Orders", f"{int(final_df['Orders'].sum())}")
                roas = final_df['Sales'].sum() / final_df['Spend'].sum() if final_df['Spend'].sum() > 0 else 0
                m4.metric("Average ROAS", f"{roas:.2f}x")

                st.divider()
                st.subheader("Cumulative Search Term Report")
                st.dataframe(final_df.style.format({
                    'Spend': '{:.2f}', 'Sales': '{:.2f}', 'ROAS': '{:.2f}x', 'ACoS': '{:.2%}'
                }), use_container_width=True)

                # --- EXPORT ---
                output = io.BytesIO()
                with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
                    # Write all original tabs (now cleaned)
                    for name, df in master_tabs.items():
                        df.to_excel(writer, sheet_name=name[:30], index=False)
                    # Add our new Analysis Tab
                    final_df.to_excel(writer, sheet_name="Cumulative Intent Analysis", index=False)
                
                st.download_button(
                    label="📥 Download Consolidated File",
                    data=output.getvalue(),
                    file_name="Master_PPC_Consolidated.xlsx",
                    mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                )
    except Exception as e:
        st.error(f"Critical Error: {e}")
