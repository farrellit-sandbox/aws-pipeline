import json, re, boto3, hashlib,  os, sys

class FileUrlReplacer:
  def __init__(self,**kwargs):
    self.entrypoint=kwargs['entrypoint']
    self.bucket = kwargs['bucket']
    self.region = kwargs['region']
    self.output = kwargs['output']
    self.client = boto3.client('s3', region_name=self.region)
    self.dryrun = bool(kwargs.get('dryrun', False))
  def PublishFile(self,**kwargs):
    path = kwargs['path']
    assert isinstance(path,str)
    data = kwargs['data'] # remember, this isn't what's in the file ; we're recursively replaceing file://.*.json
    assert isinstance(data,dict)
    normalized_content = self.NormalizeJson(data)
    chksum = hashlib.sha256(normalized_content).hexdigest()
    s3path = "{path}/{chksum}".format(path=path,chksum=chksum)
    if not self.dryrun:
      self.client.put_object(
        Body=normalized_content,
        Bucket=os.environ('BUCKET'),
        Key=s3path,
        ContentType = "application/json",
      )
    else:
      sys.stderr.write("DRY RUN , not actually pushing to s3" + "\n")
    if self.region == 'us-east-1':
      hostname = 's3'
    else:
      hostname = 's3-{region}'.format(region=self.region)
    return "https://{hostname}.amazonaws.com/{bucket}/{s3path}".format(hostname=hostname,bucket=self.bucket,s3path=s3path)

  def NormalizeJson(self, data, **kwargs):
    result = json.dumps(data,separators=(",",":"),indent=None)
    if kwargs.get('encode', True):
      result = result.encode("utf-8")
    return result
  
  def ReplaceFileUrls(self, **kwargs):
    if kwargs.get('path'):
      with open(kwargs['path'], 'r') as fi:
        data = json.loads(fi.read())
    elif kwargs.get('data'):
      data = kwargs['data']
      assert isinstance(data,dict)
    else:
      return self.ReplaceFileUrls(path=self.entrypoint,output=self.output)
    for k,v in list(data.items()):
      if isinstance(v, dict): # recrsively update sub-dictionaries
        data[k] = self.ReplaceFileUrls(data=v) 
      elif isinstance(v,str): # check strings to see if they're 
        m = re.match('^file://(.*.json)$', v)
        if m:
          path = m.group(1)
          with open(path,'r') as f:
            content = f.read()
          subdata = self.ReplaceFileUrls(data=json.loads(content))
          s3url = self.PublishFile(path=path,data=subdata)
          data[k] = s3url
    # now the entire data structure is replaced recursively
    if kwargs.get('output'):
      with open(kwargs['output'],'w') as f:
        f.write(self.NormalizeJson(data,encode=False))
    return data

if __name__ == "__main__":
  fur = FileUrlReplacer(bucket=os.environ['BUCKET'], entrypoint=os.environ['ENTRYPOINT'], output=os.environ['OUTPUT'])
  result = fur.ReplaceFileUrls()
