import streamlit as st
import pandas as pd
import io
import analyzer 

st.set_page_config(page_title="PPC Intelligence Analyzer", layout="wide")

st.sidebar.title("Settings")
# Dynamic Brand Keywords Input
brand_input = st.sidebar.text_area("Enter Brand Keywords (comma separated)", "creation lamis, scion, maison, fuse")
brand_list = [x.strip() for x in brand_input.split(',')]

st.title("📊 Cumulative Search Term & Intent Analyzer")

uploaded_files = st.file_uploader("Upload Reports", type=["xlsx", "csv"], accept_multiple_files=True)

if uploaded_files:
    try:
        all_dfs_for_summary = []
        master_tabs = {}

        for file in uploaded_files:
            if file.name.endswith('.xlsx'):
                sheets = pd.read_excel(file, sheet_name=None)
                for sheet_name, df in sheets.items():
                    df = analyzer.clean_headers(df)
                    master_tabs[sheet_name] = df
                    if any('Search Term' in str(col) for col in df.columns):
                        all_dfs_for_summary.append(df)
            else:
                df = pd.read_csv(file)
                df = analyzer.clean_headers(df)
                all_dfs_for_summary.append(df)
                master_tabs[file.name] = df

        if all_dfs_for_summary:
            with st.spinner("Analyzing Intent and Summarizing..."):
                # Pass the brand list to the analyzer
                final_summary = analyzer.standardize_and_group(all_dfs_for_summary, brand_list)
                
                # --- VISUAL SUMMARY ---
                st.subheader("Performance by Term Type")
                type_summary = final_summary.groupby('Term Type').agg({
                    'Spend': 'sum',
                    'Sales': 'sum',
                    'Orders': 'sum'
                })
                type_summary['ROAS'] = type_summary['Sales'] / type_summary['Spend']
                st.table(type_summary.style.format({'Spend': '{:.2f}', 'Sales': '{:.2f}', 'ROAS': '{:.2f}x'}))

                st.divider()
                st.subheader("Detailed Cumulative Report")
                st.dataframe(final_summary, use_container_width=True)

                # Export
                output = io.BytesIO()
                with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
                    for sheet_name, df in master_tabs.items():
                        df.to_excel(writer, sheet_name=sheet_name[:30], index=False)
                    final_summary.to_excel(writer, sheet_name="Cumulative Intent Analysis", index=False)
                
                st.download_button(
                    label="📥 Download Master File + Intent Analysis",
                    data=output.getvalue(),
                    file_name="Master_Intent_Analysis.xlsx",
                    mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                )

    except Exception as e:
        st.error(f"Error: {e}")
