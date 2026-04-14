import streamlit as st
import pandas as pd
import io
import analyzer 

st.set_page_config(page_title="PPC Analyzer Pro", layout="wide")

st.sidebar.header("Configuration")
# Pre-filled with your common brand keywords
brand_input = st.sidebar.text_area("Brand Keywords (one per line or comma-separated)", "ooze, creation lamis, scion, maison")
brand_list = [b.strip().lower() for b in brand_input.replace('\n', ',').split(',') if b.strip()]

st.title("📊 Cumulative Global PPC Analyzer")
st.info("Upload any Amazon Search Term report (India or UAE). The app will automatically detect fields and remove currency markers.")

uploaded_files = st.file_uploader("Upload Files", type=["xlsx", "csv"], accept_multiple_files=True)

if uploaded_files:
    try:
        raw_dfs_for_summary = []
        master_tabs = {}

        for file in uploaded_files:
            if file.name.endswith('.xlsx'):
                sheets = pd.read_excel(file, sheet_name=None)
                for sheet_name, df in sheets.items():
                    # Preserve every tab for the export
                    master_tabs[f"{file.name}_{sheet_name}"] = df
                    # Only analyze sheets that look like search term reports
                    if any('Search Term' in str(c) for c in df.columns):
                        raw_dfs_for_summary.append(df)
            else:
                df = pd.read_csv(file)
                master_tabs[file.name] = df
                raw_dfs_for_summary.append(df)

        if raw_dfs_for_summary:
            with st.spinner("Processing..."):
                final_df = analyzer.standardize_and_group(raw_dfs_for_summary, brand_list)
                
                # Summary Stats
                st.subheader("High-Level Metrics")
                col1, col2, col3, col4 = st.columns(4)
                col1.metric("Total Spend", f"{final_df['Spend'].sum():,.2f}")
                col2.metric("Total Sales", f"{final_df['Sales'].sum():,.2f}")
                col3.metric("Total Orders", f"{int(final_df['Orders'].sum())}")
                roas = final_df['Sales'].sum() / final_df['Spend'].sum() if final_df['Spend'].sum() > 0 else 0
                col4.metric("Global ROAS", f"{roas:.2f}x")

                st.divider()
                st.subheader("Cumulative Search Term Analysis")
                st.dataframe(final_df, use_container_width=True)

                # Excel Export
                output = io.BytesIO()
                with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
                    # Keep original data
                    for name, df in master_tabs.items():
                        df.to_excel(writer, sheet_name=name[:30], index=False)
                    # Add our new analysis
                    final_df.to_excel(writer, sheet_name="Cumulative Analysis", index=False)
                
                st.download_button(
                    label="📥 Download Master Report",
                    data=output.getvalue(),
                    file_name="PPC_Consolidated_Analysis.xlsx",
                    mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                )
    except Exception as e:
        st.error(f"Error during processing: {e}")
