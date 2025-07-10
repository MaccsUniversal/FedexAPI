const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const os = require('os');
const exe = require('child_process');
const ngrok = require('ngrok');
const { dirname } = require('path');
const { error } = require('console');


let printLabels;
let salesOrderNo;
let iType;

const app = express();
const PORT = process.env.PORT || '3000';

app.use(bodyParser.json({limit: '10mb'}));

app.get('/',(req,res) => {
    res.send('Fedex-BC integration');
})

app.post('/print',async (req,res,next)=>{
    const{labels} = req.body;
    const{salesOrderNumber} = req.body;
    const{imageType} =req.body;
    if(labels == undefined){
        res.send({
            error: 'Bad-Request',
            message: 'base64 Image not received, please check your input and resend.'
        })
    } else {
        res.send({
            success: 'success',
            message: 'labels received successfully'
        })
        makeDir();
        setSalesOrderNumber(salesOrderNumber);
        setLabels(labels);
        setImageType(imageType);
        openDirForOrder();
    }
})

async function setLabels(labels){
    printLabels = labels;
}

async function setSalesOrderNumber(orderNumber){
    salesOrderNo = orderNumber;
}

async function setImageType(type){
    switch(type){
        case 'PDF':
            iType = 'pdf';
            break;
        case 'PNG':
            iType = 'png';
            break;
        case 'ZPLII':
            iType = 'zpl';
            break;
        case 'EPL2':
            iType = 'epl';
            break;
        default:
            console.error('Cannot recognize imagetype. please contact administrator for assitance.');
    } 

}

async function makeDir(){
    if (fs.existsSync('./Fedex_BC_Labels')){
        console.log('Fedex_BC_Labels folder exists');
    } else {
        fs.mkdir('./Fedex_BC_Labels', (err) =>{
            if(err){
                if (err.errno == -4075){
                    console.log(err.message);
                } else if(err.errno != -4075) {
                    console.error(err);
                }
            }
        });
    }

}

async function openDirForOrder(){
    let fileDir = './Fedex_BC_Labels/' + salesOrderNo;
    if(fs.existsSync(fileDir)){
        fs.readdir(fileDir,(err,files) =>{
            if(err){
                console.error(err);
            } else {
                files.forEach(file =>{
                    fs.unlink(fileDir + '/' + file,(err) =>{
                        if(err){
                            if(err.code = -4058){

                            } else {
                                console.error(err);
                            }
                        } else {
                            console.log('deleted file ', file);
                        }
                    })
                })
                removeMetaData(printLabels);
            }
        })
    } else {
        fs.mkdir(fileDir, (err) =>{
            if(err){
                if (err.errno == -4075){
                    console.log(err.message);
                } else {
                    console.log(err);
                }
            }
            removeMetaData(printLabels);
        });
    }
    


}

async function removeMetaData(labels) {
    for(var i = 0; i < labels.length; i++){
        const {EncodedLabel} = labels[i];
        EncodedLabel.replace(/^EncodedLabel:\/\w+;base64,/, ''); 
        decodeBase64(EncodedLabel, i);       
    }   
    produceBatFile();
}

async function decodeBase64(base64Data, index){
    var buffer = Buffer.from(base64Data,'base64');
    saveImage(wasFileAppended, buffer, index);
}

var wasFileAppended = async function(err, ok){
    if (err) throw err;
    ok;
}

async function saveImage(callback, buffer, ind){
   fs.writeFile('./Fedex_BC_Labels/'+ salesOrderNo + '/label' + ind + '.' + iType, buffer, (err) => {
        if(err) {
            console.error('Error: ', err + ' occured with label ' + ind + ' in folder ' + os.homedir + '/Desktop/Fedex_BC_Labels/'+ salesOrderNo);
            callback(err, false);
        } else {
            console.log('label ' + ind + ' saved to folder ' + os.homedir + '/Desktop/Fedex_BC_Labels/'+ salesOrderNo);
            callback(null, true);
        }
    })
}


async function produceBatFile(){
    const script = '@echo off\nsetlocal\n\n@echo starting process...\n\nset "folder=' + './Fedex_BC_Labels/'+ salesOrderNo + '"\nset "printer=TSC DA210"\n\n@echo Default printer set to %printer%\n\nRUNDLL32 PRINTUI.DLL,PrintUIEntry /y /n "%printer%"\n\nfor %%f in ("%folder%\*.png") do (\n' + '    mspaint /pt "%%f" "%printer%"'  + '\n' + '    @echo printed %%f\n' + '    timeout /t 5 >nul' + '\n' + ')\n\n' + '@echo Default Task Complete!';
    fs.writeFile('./Fedex_BC_Labels/'+ salesOrderNo + '/printfile.bat', script, (err) =>{
        if(err){
            console.error('printfile Error: ', err);
        } else {
            console.log('Print file for ' + salesOrderNo + ' successfully deployed');
        }
    })
    executePrintFile();
}

async function executePrintFile(){
    exe.exec('./Fedex_BC_Labels/'+ salesOrderNo + '/printfile.bat', (error, stdout, stderr) =>{
        if(error){
            console.error('printfile Error: ', error);
        } else {
            console.log('printfile Output: ', stdout);
            console.log('printfile Output Error: ', stderr);
        }
    })
}

app.listen(PORT, ()=>{
    console.log('Fedex print server running on port: ', PORT);
},)