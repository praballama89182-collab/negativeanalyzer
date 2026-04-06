import streamlit as st
import pandas as pd
import io
from analyzer import load_bulk_file, aggregate_data, perform_ngram_analysis

st.set_page_config(page_title="Bulk File Analysis Preserver", layout="wide")
st.title("🚀 Amazon Bulk File: Global Analysis & Tab Preserver")

uploaded_file = st.file_uploader("Upload Original Bulk File (.xlsx)", type=["xlsx"])

if uploaded_file:
    try:
        with st.spinner("Processing..."):
            # 1. Load everything
            sp_df, sb_df, all_sheets = load_bulk_file(uploaded_file)
            
            # 2. Run Global Analysis
            global_results = aggregate_data(sp_df, sb_df)
            ngram_sizes = [1, 2, 3]
            analysis_tabs = {size: perform_ngram_analysis(global_results, size) for size in ngram_sizes}

        st.success("Analysis Complete. Ready for Full Export.")

        # --- EXPORT LOGIC ---
        output = io.BytesIO()
        with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
            # STEP A: Write all ORIGINAL tabs exactly as they were
            for sheet_name, df in all_sheets.items():
                df.to_excel(writer, sheet_name=sheet_name, index=False)
            
            # STEP B: Append NEW Analysis tabs
            for size, df in analysis_tabs.items():
                df.to_excel(writer, sheet_name=f"{size}-Gram Global Analysis", index=False)
        
        processed_data = output.getvalue()

        st.download_button(
            label="📥 Download Updated Bulk File with Analysis",
            data=processed_data,
            file_name="Bulk_File_With_Global_Analysis.xlsx",
            mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )

    except Exception as e:
        st.error(f"Error: {e}")
