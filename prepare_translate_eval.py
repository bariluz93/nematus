import pickle
from typing import List
import re
CONSTS_CONFIG_FILE ="/cs/labs/gabis/bareluz/nematus_clean/nematus/consts_config.json"#TODO make this not user specific

def separate_bad_sentences(translate_separate_bad_lines_file: str, source_files: List[str], target_files:List[str]):
    p = re.compile('line number ([0-9]+) wasn\'t translated')
    lines_to_remove = []
    with open(translate_separate_bad_lines_file,"r") as f:
        while True:
            line = f.readline()
            if not line:
                break
            m = p.match(line)
            if m:
                line_num = int(m.group(1))
                lines_to_remove.append(line_num)
    print(lines_to_remove)
    for s,t in zip(source_files,target_files):
        line_num = 0
        with open(s,'r') as s1, open(t,'w') as t1:
            while True:
                s_line = s1.readline()
                if not s_line:
                    break
                line_num+=1
                if line_num not in lines_to_remove:
                    t1.write(s_line)
                else:
                    print("removing line: " + s_line)
def file_to_list(source_file,dest_file):
    lines = []
    with open(source_file,"r") as f:
        while True:
            line = f.readline()
            if not line:
                break
            lines.append(line)
    with open(dest_file, "wb") as f:
        pickle.dump(lines,f)

if __name__ == '__main__':
    from nematus.consts import get_evaluate_translate_files

    TRANSLATE_SEPARATE_BAD_LINES, BLEU_SOURCE_DATA, BLEU_GOLD_DATA, BLEU_SOURCE_DATA_FILTERED, BLEU_GOLD_DATA_FILTERED, \
    BLEU_SOURCE_DATA_FILTERED2, BLEU_GOLD_DATA_FILTERED2, TRANSLATED_DEBIASED, TRANSLATED_NON_DEBIASED, TRANSLATED_NON_DEBIASED2, \
    TRANSLATED_DEBIASED_PICKLE, TRANSLATED_NON_DEBIASED_PICKLE, BLEU_GOLD_DATA_FILTERED_PICKLE = get_evaluate_translate_files(CONSTS_CONFIG_FILE)
    # separate_bad_sentences(TRANSLATE_SEPARATE_BAD_LINES, [BLEU_SOURCE_DATA, BLEU_GOLD_DATA], [BLEU_SOURCE_DATA_FILTERED, BLEU_GOLD_DATA_FILTERED])
    # separate_bad_sentences(TRANSLATE_SEPARATE_BAD_LINES, [BLEU_SOURCE_DATA_FILTERED, BLEU_GOLD_DATA_FILTERED,TRANSLATED_NON_DEBIASED], [BLEU_SOURCE_DATA_FILTERED2, BLEU_GOLD_DATA_FILTERED2, TRANSLATED_NON_DEBIASED2])
    file_to_list(TRANSLATED_DEBIASED, TRANSLATED_DEBIASED_PICKLE)
    file_to_list(TRANSLATED_NON_DEBIASED2, TRANSLATED_NON_DEBIASED_PICKLE)
    file_to_list(BLEU_GOLD_DATA_FILTERED2,BLEU_GOLD_DATA_FILTERED_PICKLE)