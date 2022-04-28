#!/bin/bash
set -e
#SBATCH --mem=128g
#SBATCH -c4
#SBATCH --time=7-0
#SBATCH --mail-type=BEGIN,END,FAIL,TIME_LIMIT
#SBATCH --mail-user=bar.iluz@mail.huji.ac.il
#SBATCH --output=/cs/usr/bareluz/gabi_labs/nematus_clean/nematus/slurm/evaluate_gender_bias-%j.out
echo "**************************************** in evaluate_gender_bias.sh ****************************************"

SHORT=l:,d:,p,t,h
LONG=language:,debias_method:,preprocess,translate,help
OPTS=$(getopt -a -n debias --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

preprocess=false
translate=false

while :
do
  case "$1" in
    -l | --language )
      language="$2"
      shift 2
      ;;
    -d | --debias_method )
      debias_method="$2"
      shift 2
      ;;
    -p | --preprocess )
      preprocess=true
      shift 1
      ;;
    -t | --translate )
      translate=true
      shift 1
      ;;
    -h | --help)
      echo "usage:
Mandatory arguments:
  -l, --language                  the destination translation language .
  -d, --debias_method             the debias method .
Optional arguments:
  -p, --preprocess                preprocess the anti dataset .
  -t, --translate                 translate the entire dataset .
  -h, --help                      help message ."
      exit 2
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      exit 1;;
  esac
done

scripts_dir=`pwd`
source ${scripts_dir}/consts.sh ${language} ${debias_method}

############preprocess###############
if [ $preprocess = true ]; then
  echo "#################### preprocess ####################"
  echo "sh ${nematus_dir}/global_preprocess.sh ${dst_language}"
  sh ${nematus_dir}/global_preprocess.sh ${dst_language}
fi


#################### translate anti sentences to test gender bias ####################
input_path=${nematus_dir}/${language_dir}/preprocess/anti.unesc.tok.tc.bpe.en
#echo "input_path: ${input_path}"
model_type=bpe256
model_name=model.npz
model_dir=${nematus_dir}/${language_dir}/scripts/models/${model_type}/${model_name}
#echo "model_dir: ${model_dir}"
#output_filename_debiased=debiased_anti_TEST.out.tmp
outputh_path_debiased=${nematus_dir}/${language_dir}/output/debiased_anti_${debias_method}.out.tmp
outputh_path_non_debiased=${nematus_dir}/${language_dir}/output/non_debiased_anti_${debias_method}.out.tmp
#echo "outputh_path_debiased: ${outputh_path_debiased}"
#echo "outputh_path_non_debiased: ${outputh_path_non_debiased}"
config_debiased="{'USE_DEBIASED': 1, 'LANGUAGE': ${language_num}, 'COLLECT_EMBEDDING_TABLE': 0, 'DEBIAS_METHOD': ${debias_method}}"
#echo "config_debiased: ${config_debiased}"
config_non_debiased="{'USE_DEBIASED': 0, 'LANGUAGE': ${language_num}, 'COLLECT_EMBEDDING_TABLE': 0, 'DEBIAS_METHOD': ${debias_method}}"

if [ $translate = true ]; then
  echo "#################### translate anti debias ####################"
#  echo "python ${nematus_dir}/nematus/translate.py -i ${input_path} -m ${model_dir} -k 12 -n -o ${outputh_path_debiased} -c ${config_debiased}"
  python ${nematus_dir}/nematus/translate.py \
       -i "$input_path" \
       -m "$model_dir" \
       -k 12 -n -o "${outputh_path_debiased}" -c "${config_debiased}"
  echo "#################### translate anti non debias ####################"
#  echo "python ${nematus_dir}/nematus/translate.py -i ${input_path} -m ${model_dir} -k 12 -n -o ${outputh_path_non_debiased} -c ${config_non_debiased}"
  python ${nematus_dir}/nematus/translate.py \
       -i "$input_path" \
       -m "$model_dir" \
       -k 12 -n -o "${outputh_path_non_debiased}" -c "${config_non_debiased}"
fi


#echo "#################### merge translations ####################"
#python ${nematus_dir}/merge_translations.py \
#     -c "{'USE_DEBIASED': 0, 'LANGUAGE': ${language_num}, 'COLLECT_EMBEDDING_TABLE': 0, 'DEBIAS_METHOD': ${debias_method}}" \
#     -e 0
echo "#################### prepare gender data ####################"
python ${nematus_dir}/prepare_gender_data.py  -c "${config_non_debiased}"

echo "#################### gender evaluation ####################"
output_result_path=${nematus_dir}/${language_dir}/debias/gender_evaluation_${dst_language}_${debias_method}.txt
exec > ${output_result_path}
exec 2>&1
cd /cs/usr/bareluz/gabi_labs/nematus_clean/mt_gender
source venv/bin/activate
cd src
sh ../scripts/evaluate_debiased.sh ${language} ${debias_method}




