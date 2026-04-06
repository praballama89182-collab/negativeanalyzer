import streamlit as st
import pandas as pd
import io
from analyzer import load_bulk_file, aggregate_data, perform_ngram_analysis

st.set_page_config(page_title="Global PPC Negative Analyzer", layout="wide")

st.title("🚀 Global PPC Keyword Redundancy Analyzer")
st.info("This tool aggregates performance for the same keyword across different campaigns.")

# Sidebar Settings
with st.sidebar:
    ngram_sizes = st.multiselect("Select N-Grams:", [1, 2, 3], default=[1, 2, 3])
    target_asin = st.text_input("Target ASIN (Optional)")

uploaded_file = st.file_uploader("Upload Amazon Bulk File (.xlsx)", type=["xlsx"])

if uploaded_file:
    try:
        with st.spinner("Analyzing Search Terms across all campaigns..."):
            # 1. Load data but keep reference to 'all_sheets' to preserve other tabs
            sp_df, sb_df, all_sheets = load_bulk_file(uploaded_file)
            
            # 2. Perform the Global Aggregation (Cross-Campaign)
            global_results = aggregate_data(sp_df, sb_df)
            
            # 3. Generate N-Grams from the Global Data
            analysis_results = {size: perform_ngram_analysis(global_results, size) for size in ngram_sizes}

        # --- Dashboard Metrics ---
        st.subheader("Global Wasted Spend Account-Wide")
        waste = global_results[global_results['Sales'] == 0]['Spend'].sum()
        st.metric("Total Spend with 0 Sales", f"${waste:,.2f}")

        # --- Display Previews ---
        cols = st.columns(len(ngram_sizes))
        for idx, size in enumerate(ngram_sizes):
            with cols[idx]:
                st.write(f"### {size}-Gram Global Performance")
                # Show Term and Campaign Count (Redundancy)
                display = analysis_results[size][['Term', 'Campaign Count', 'Spend', 'Sales', 'ACOS']]
                st.dataframe(display.head(20), use_container_width=True)

        # --- Export to Excel ---
        # We create a NEW excel file for the Analysis Report
        output = io.BytesIO()
        with pd.ExcelWriter(output, engine='openpyxl') as writer:
            for size, df in analysis_results.items():
                df.to_excel(writer, sheet_name=f"{size}-Gram Global Analysis", index=False)
        
        st.download_button(
            label="📥 Download Global Analysis Report",
            data=output.getvalue(),
            file_name="PPC_Global_Redundancy_Report.xlsx",
            mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )

    except Exception as e:
        st.error(f"Error: {e}")
        st.warning("Ensure your Bulk File contains 'SP Search Term Report' and 'SB Search Term Report' tabs.")
