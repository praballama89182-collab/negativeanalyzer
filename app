import streamlit as st
import pandas as pd
import io
from analyzer import load_bulk_file, aggregate_exact_campaign_metrics

st.title("Exact Keyword Campaign Summarizer")

uploaded_file = st.file_uploader("Upload Bulk File", type=["xlsx"])

if uploaded_file:
    # 1. Load data and all original tabs
    sp_df, sb_df, all_sheets = load_bulk_file(uploaded_file)
    
    # 2. Summarize Exact keywords within the same campaigns
    summary_df = aggregate_exact_campaign_metrics(sp_df, sb_df)
    
    st.write("### Summary of Exact Keywords by Campaign")
    st.dataframe(summary_df)

    # --- THE EXPORT BUTTON LOGIC ---
    output = io.BytesIO()
    with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
        # Write back all original unchanged tabs
        for sheet_name, df in all_sheets.items():
            df.to_excel(writer, sheet_name=sheet_name, index=False)
        
        # Append the new Exact Keyword Summary tab
        summary_df.to_excel(writer, sheet_name="Exact Keyword Summary", index=False)
    
    # THE ACTUAL EXPORT BUTTON
    st.divider()
    st.download_button(
        label="📥 Export All Tabs + Exact Summary",
        data=output.getvalue(),
        file_name="Summarized_PPC_Report.xlsx",
        mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
