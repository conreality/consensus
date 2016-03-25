# This is free and unencumbered software released into the public domain.

"""Messaging protocols."""

from .storage import DataDirectory
from select import PIPE_BUF, select
import os
import threading

DATA_PATH = 'topics'

class TopicRegistry(DataDirectory):
  """Topic registry."""

  def __init__(self, path=None):
    if path:
      self.path = str(path)
    else:
      super().__init__(DATA_PATH)

  def topics(self):
    """Yields each of the topics in this topic registry."""
    for entry in self.scan():
      if not entry.name.startswith('.') and entry.is_dir():
        yield Topic(path=os.path.join(self.path, entry.name))

class Topic(DataDirectory):
  """Topic exchange."""

  def __init__(self, path=None, name=None):
    if name:
      self.name = name
      super().__init__(DATA_PATH, name)
    elif path:
      self.path = str(path)
      self.name = os.path.basename(self.path)
    else:
      raise ValueError("no topic name or path specified")
    self.open(mode='r+')

  def publish(self, message):
    """Publishes a message to subscribers of this topic."""
    return Publisher(topic=self).publish(message)

  def subscribe(self):
    """Creates a new subscriber for this topic."""
    return Subscriber(topic=self)

  def subscribers(self, numeric=False):
    """Yields each of the subscribers of this topic."""
    for entry in self.scan():
      if entry.name.isnumeric():
        yield Subscriber(topic=self, id=int(entry.name))

class Subscriber:
  """Message subscriber."""

  PIPE_MODE  = 0o666
  PIPE_FLAGS = os.O_RDONLY | os.O_NONBLOCK | os.O_CLOEXEC

  def __init__(self, topic, id=None):
    self.topic = topic
    self.id = int(id) if id else threading.get_ident()
    self.path = os.path.join(self.topic.path, str(self.id))
    self.fd = None

  def __enter__(self):
    self.open()
    return self

  def __exit__(self, *args):
    self.close()
    return False

  def open(self):
    """Establishes the subscription to the subscriber topic."""
    assert not self.fd
    os.mkfifo(self.path, mode=self.PIPE_MODE)
    self.fd = os.open(self.path, flags=self.PIPE_FLAGS)
    return self

  def close(self):
    """Cancels the subscription to the subscriber topic."""
    os.unlink(self.path)
    if self.fd:
      os.close(self.fd)
      self.fd = None
    return self

  def receive(self, timeout=None):
    """Returns the next message published to the subscriber topic."""
    assert self.fd
    select([self.fd], [], [], timeout) # FIXME: check return value
    buffer = os.read(self.fd, PIPE_BUF)
    message = buffer.decode() # TODO: Message(data=buffer)
    return message

class Publisher:
  """Message publisher."""

  PIPE_FLAGS = os.O_WRONLY | os.O_NONBLOCK | os.O_CLOEXEC

  def __init__(self, topic, id=None):
    self.topic = topic
    self.id = int(id) if id else threading.get_ident()

  def __enter__(self):
    self.open()
    return self

  def __exit__(self, *args):
    self.close()
    return False

  def open(self):
    # TODO: open all subscriber pipes and watch for new subscribers.
    return self

  def close(self):
    # TODO: close all subscriber pipes and cancel watch.
    return self

  def publish(self, message):
    """Publishes a message to the publisher topic."""
    buffer = message.encode() if type(message) is not bytes else message
    if len(buffer) > PIPE_BUF:
      raise ValueError("message size {} exceeds PIPE_BUF={} bytes".format(len(buffer), PIPE_BUF))
    deliveries = set()
    for subscriber in self.topic.subscribers():
      fd = os.open(subscriber.path, flags=self.PIPE_FLAGS)
      try:
        os.write(fd, buffer)
        deliveries.add(subscriber.id)
      finally:
        os.close(fd)
    return deliveries
