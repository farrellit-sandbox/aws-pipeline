import pytest, tempfile, hashlib, json, os
from publish_templates import FileUrlReplacer


os.chdir("/tmp")

def test_NormalizeJson():
  x = FileUrlReplacer(bucket='bucket', region='us-east-1', entrypoint='test.json', dryrun=True, output='result.json')
  assert x.NormalizeJson([{"A":1,"B":2},"C",3,None]) == '[{"A":1,"B":2},"C",3,null]'.encode('utf-8')

def test_PublishFile():
  with tempfile.NamedTemporaryFile() as f:
    x = FileUrlReplacer(bucket='bucket', region='us-east-1', entrypoint='test.json', dryrun=True, output='result.json' )
    f.write(x.NormalizeJson('{}'))
    f.flush()
    expected_hash = hashlib.sha256("{}".encode('utf-8')).hexdigest()
    assert x.PublishFile(path=f.name,data={}) == \
      'https://s3.amazonaws.com/bucket/' + f.name + '/' + expected_hash 
    x = FileUrlReplacer(bucket='bucket', region='us-east-2', entrypoint='test.json', dryrun=True, output='result.json' )
    assert x.PublishFile(path=f.name,data={}) == \
      'https://s3-us-east-2.amazonaws.com/bucket/' + f.name + '/' + expected_hash 
 
def test_ReplaceFileUrls():
  with open('entry.json','w') as f:
    f.write( json.dumps({"filepath": "file://test.json"}) )
  with open('test.json','w') as f:
    f.write( json.dumps({"nested": {"inner_filepath": "file://test2.json"}}) )
  test2data = {"A": [1,2,3], "B": "456" }
  with open('test2.json','w') as f:
    f.write( json.dumps(test2data) )
  x = FileUrlReplacer(bucket='bucket', region='us-east-1', entrypoint='entry.json', dryrun=True, output='result.json' )
  res = x.ReplaceFileUrls(path='test2.json')
  assert res == test2data
  res = x.ReplaceFileUrls(path='test.json')
  expected_hash = hashlib.sha256(x.NormalizeJson(test2data)).hexdigest()
  expected_test_data = { "nested": { "inner_filepath": "https://s3.amazonaws.com/bucket/test2.json/" + expected_hash } }
  assert res == expected_test_data
  res = x.ReplaceFileUrls()
  expected_hash = hashlib.sha256(x.NormalizeJson(test2data)).hexdigest()
  expected_test_data_hash = hashlib.sha256(x.NormalizeJson(expected_test_data)).hexdigest()
  assert res == { "filepath": "https://s3.amazonaws.com/bucket/test.json/" + expected_test_data_hash }
  with open('result.json', 'r') as f:
    assert json.loads(f.read()) == res
