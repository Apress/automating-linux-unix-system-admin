#!/bin/bash

# Start the agent (don't display PID)
eval `ssh-agent` >/dev/null
# Now, ask for the key once
ssh-add

# Now, perform a bunch of SSH operations
ssh host1 'command1'
ssh host1 'command2'
ssh host2 'command3'

# Finally, kill the agent and exit
kill $SSH_AGENT_PID
exit 0
