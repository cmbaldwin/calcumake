import git_filter_repo as fr

def blob_callback(blob, metadata):
    try:
        data = blob.data.decode('utf-8')
    except UnicodeDecodeError:
        return # Skip binary files

    # The leaked key
    leaked_key = 'c121a78b1752ec963e41b59e8dc6f7864346e94e5c62acfb5a385821fda575aa07ba0a5edb2d5ada03af8721ef9ce0cf3a10b442de6cdd1e1705b39ce13b80d0'
    
    if leaked_key in data:
        # Replace with a safe placeholder
        data = data.replace(leaked_key, 'hub_secret_key_REDACTED_BY_SECURITY_AUDIT')
        blob.data = data.encode('utf-8')

args = fr.FilteringOptions.parse_args(['--force'])
fr.RepoFilter(args, blob_callback=blob_callback).run()
