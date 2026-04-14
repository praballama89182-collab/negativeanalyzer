import streamlit as st
import pandas as pd
import io
import analyzer # Ensure analyzer.py is in the same folder

st.set_page_config(page_title="PPC Master Analyzer", layout="wide")
st.title("📊 Cumulative Search Term & Bulk File Analyzer")

uploaded_files = st.file_uploader(
    "Upload Amazon Reports (India/UAE/Bulk)", 
    type=["xlsx", "csv"], 
    accept_multiple_files=True
)

if uploaded_files:
    try:
        all_dfs_for_summary = []
        master_tabs = {} # To store all original sheets

        for file in uploaded_files:
            if file.name.endswith('.xlsx'):
                # Load every sheet in the Excel file
                sheets = pd.read_excel(file, sheet_name=None)
                for sheet_name, df in sheets.items():
                    # Clean headers for every sheet immediately
                    df = analyzer.clean_headers(df)
                    master_tabs[sheet_name] = df
                    
                    # If this sheet looks like it has search term data, add to summary list
                    if any('Search Term' in str(col) for col in df.columns):
                        all_dfs_for_summary.append(df)
            else:
                # Handle CSV
                df = pd.read_csv(file)
                df = analyzer.clean_headers(df)
                all_dfs_for_summary.append(df)
                master_tabs[file.name] = df

        if all_dfs_for_summary:
            with st.spinner("Generating Cumulative Summary..."):
                final_summary = analyzer.standardize_and_group(all_dfs_for_summary)
                
                st.subheader("Preview: Cumulative Search Terms")
                st.dataframe(final_summary.head(100), use_container_width=True)

                # Export Section
                output = io.BytesIO()
                with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
                    # 1. Write back ALL original tabs (now with cleaned headers)
                    for sheet_name, df in master_tabs.items():
                        # Sheet names in Excel must be < 31 chars
                        safe_name = sheet_name[:30]
                        df.to_excel(writer, sheet_name=safe_name, index=False)
                    
                    # 2. Add the NEW Cumulative sheet
                    final_summary.to_excel(writer, sheet_name="Cumulative Summary", index=False)
                
                st.divider()
                st.download_button(
                    label="📥 Download Full File (All Tabs + Cumulative)",
                    data=output.getvalue(),
                    file_name="Master_PPC_Analysis.xlsx",
                    mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                )
        else:
            st.error("No 'Search Term' columns found in the uploaded files.")

    except Exception as e:
        st.error(f"Error: {e}")
