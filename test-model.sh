port=1234
model_path=$1
model_basename=`basename $model_path`
model_name="${model_basename%.*}"

class_names_path=$2

# install packages
cd template && yarn && yarn build && cd ..

# copy template to $model_name
rsync -a template/dist/ output/$model_name

if ! test -f "output/$model_name/model/model.json"; then

    # convert model from keras to tfjs
    CUDA_VISIBLE_DEVICES='' tensorflowjs_converter \
        --input_format keras \
        $model_path \
        output/$model_name/model \
        --output_format tfjs_graph_model

    # copy class names from txt to json
    python -c \
        'import json; \
        data = open("'$class_names_path'").read().splitlines(); \
        print(json.dumps(data, indent=True))' >> output/$model_name/model/class_names.json

fi

# serve
cd output/$model_name && python -m http.server $port