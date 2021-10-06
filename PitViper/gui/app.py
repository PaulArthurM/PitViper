#!/home/paularthur/miniconda3/bin/python
import os
from flask import Flask, render_template, request, redirect, url_for
from werkzeug.utils import secure_filename
import yaml

UPLOAD_FOLDER = 'data/upload/'
ALLOWED_EXTENSIONS = {'txt', 'tsv', 'csv'}

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/')
def index():
    return render_template('index.html')


@app.route('/documentation')
def documentation():
    return 'Documentation!  '


def get_config(form_results):
    parameters_cmd = "python3 pitviper_config.py"
    for parameter in form_results:
        value = form_results[parameter]
        if value == "":
            value = "none"
        parameters_cmd += " --{param} {value}".format(param=parameter, value=value)
    print(parameters_cmd)
    os.system(parameters_cmd)

def run_pitviper(token):
    configfile = 'config/{token}.yaml'.format(token=token)
    cmd = "python3 pitviper.py --run_snakemake True --configfile {conf} --jobs 5".format(conf=configfile)
    print(cmd)
    os.chdir('../')
    os.system(cmd)

@app.route('/result',methods = ['POST', 'GET'])
def result():
    result = request.form
    result_dict = dict(result)
    if request.method == 'POST':
        library_file = request.files['library_file']
        tsv_file = request.files['tsv_file']
        count_table_file = request.files['count_table_file']

    if not os.path.exists('../resources/' + result_dict['token'] + '/'):
        os.makedirs('../resources/' + result_dict['token'] + '/')

        library_filename = '../resources/' + result_dict['token'] + '/' + library_file.filename
        tsv_filename = '../resources/' + result_dict['token'] + '/' +  tsv_file.filename

        library_file.save(library_filename)
        tsv_file.save(tsv_filename)

        result_dict['library_file'] = library_filename[3:]
        result_dict['tsv_file'] = tsv_filename[3:]

        if count_table_file.filename != '':
            count_table_filename = '../resources/' + result_dict['token'] + '/' + count_table_file.filename
            count_table_file.save(count_table_filename)
            result_dict['count_table_file'] = count_table_filename[3:]

        if result_dict['bagel_activate'] == 'False':
            result_dict['nonessentials'] = ''
            result_dict['essentials'] = ''
        else:
            ess = request.files['essentials']
            ess_filename = '../resources/' + result_dict['token'] + '/' + ess.filename
            ess.save(ess_filename)

            non_ess = request.files['nonessentials']
            noness_filename = '../resources/' + result_dict['token'] + '/' + non_ess.filename
            non_ess.save(noness_filename)

            result_dict['nonessentials'] = noness_filename[3:]
            result_dict['essentials'] = ess_filename[3:]

        yaml_file_name = '../config/' + result['token'] + '.yaml'
        with open(yaml_file_name, 'w') as file:
          documents = yaml.dump(result_dict, file)
        # get_config(result)
        run_pitviper(token=result_dict['token'])
        return render_template("result.html",result = result)
