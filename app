import streamlit as st
import pandas as pd
import io
from analyzer import load_bulk_file, aggregate_unique_search_terms

st.set_page_config(page_title="Cumulative PPC Analyzer", layout="wide")

st.title("📊 Cumulative Search Term Analyzer")
st.markdown("Summarizing multi-row search term repeats into single rows with **Sales & ROAS**.")

uploaded_file = st.file_uploader("Upload your Amazon Bulk File (.xlsx)", type=["xlsx"])

if uploaded_file:
    try:
        with st.spinner("Processing Bulk File and Calculating Metrics..."):
            # 1. Load and Process
            sp_df, sb_df, all_sheets = load_bulk_file(uploaded_file)
            final_df = aggregate_unique_search_terms(sp_df, sb_df)
            
            if final_df.empty:
                st.warning("No search term data found in the uploaded file.")
            else:
                # 2. Display Dataframe with proper formatting
                st.subheader("Cumulative Performance Summary")
                
                # Apply styling for the UI
                styled_df = final_df.style.format({
                    'Spend': '${:.2f}',
                    '7 Day Total Sales': '${:.2f}',
                    'CPC': '${:.2f}',
                    'ROAS': '{:.2f}x',
                    'ACoS': '{:.2%}'
                })
                
                st.dataframe(styled_df, use_container_width=True)

                # 3. Export Section
                st.divider()
                st.write("### 📥 Download Results")
                
                output = io.BytesIO()
                with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
                    # Write original tabs so the file remains useful as a bulk file
                    for sheet_name, df in all_sheets.items():
                        df.to_excel(writer, sheet_name=sheet_name, index=False)
                    
                    # Add the new analysis tab
                    final_df.to_excel(writer, sheet_name="Cumulative Analysis", index=False)
                
                st.download_button(
                    label="Download Excel with Cumulative Tab",
                    data=output.getvalue(),
                    file_name="PPC_Cumulative_Report.xlsx",
                    mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                )

    except Exception as e:
        st.error(f"An error occurred: {e}")
        st.info("Check if your bulk file contains the standard '7 Day Total Sales' and 'Search Term' columns.")
