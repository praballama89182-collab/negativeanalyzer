import streamlit as st
import pandas as pd
import io
from analyzer import load_bulk_file, aggregate_unique_search_terms

st.set_page_config(page_title="Cumulative PPC Analyzer", layout="wide")
st.title("📊 Cumulative Search Term Analyzer")
st.markdown("Summarizing repeats into single rows per campaign.")

uploaded_file = st.file_uploader("Upload your Amazon Bulk File (.xlsx)", type=["xlsx"])

if uploaded_file:
    try:
        with st.spinner("Calculating cumulative values..."):
            # Load original tabs to preserve them
            sp_df, sb_df, all_sheets = load_bulk_file(uploaded_file)
            
            # Generate the unique, summarized table
            final_df = aggregate_unique_search_terms(sp_df, sb_df)
            
            # Display the result in the app
            st.subheader("Summarized Metrics (One Row Per Term Per Campaign)")
            st.dataframe(final_df, use_container_width=True)

            # --- EXPORT SECTION ---
            st.divider()
            st.write("### Export Options")
            
            output = io.BytesIO()
            with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
                # 1. Write back ALL original tabs (Portfolios, Campaigns, etc.)
                for sheet_name, df in all_sheets.items():
                    df.to_excel(writer, sheet_name=sheet_name, index=False)
                
                # 2. Add the NEW Cumulative Summary tab
                final_df.to_excel(writer, sheet_name="Cumulative Search Terms", index=False)
            
            # THE DOWNLOAD BUTTON
            st.download_button(
                label="📥 Download Full File + Cumulative Summary",
                data=output.getvalue(),
                file_name="PPC_Cumulative_Analysis.xlsx",
                mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            )

    except Exception as e:
        st.error(f"Analysis Error: {e}")
