import { useEffect, useRef, useState } from "react";
import { Outlet, useNavigate, Link } from "react-router-dom";
import NoteList from "./NoteList";
import { v4 as uuidv4 } from "uuid";
import { currentDate } from "./utils";
import React from 'react';
import { googleLogout, useGoogleLogin } from '@react-oauth/google';
import axios from 'axios';


const localStorageKey = "lotion-v1";

function Layout() {
  const navigate = useNavigate();
  const mainContainerRef = useRef(null);
  const [collapse, setCollapse] = useState(false);
  const [notes, setNotes] = useState([]);
  const [editMode, setEditMode] = useState(false);
  const [currentNote, setCurrentNote] = useState(-1);
  const [user, setUser] = useState(JSON.parse(localStorage.getItem("user_token")) ? JSON.parse(localStorage.getItem("user_token")) : []);
  const [profile, setProfile] = useState(JSON.parse(localStorage.getItem("user")) ? JSON.parse(localStorage.getItem("user")) : null);




  const login = useGoogleLogin({
    onSuccess: (codeResponse) => { setUser(codeResponse); },
    onError: (error) => console.log('Login Failed:', error)
  });



  useEffect(() => {
    const height = mainContainerRef.current.offsetHeight;
    mainContainerRef.current.style.maxHeight = `${height}px`;
    const existing = localStorage.getItem("user");
    if (existing) {
      try {
        setProfile(JSON.parse(existing));
      } catch {
        setProfile(null);
      }
    }
  }, []);


  useEffect(() => {
    const height = mainContainerRef.current.offsetHeight;
    mainContainerRef.current.style.maxHeight = `${height}px`;
    const existing = localStorage.getItem("user_token");
    if (existing) {
      try {
        setUser(JSON.parse(existing));
      } catch {
        setUser([]);
      }
    }
  }, []);

  useEffect(() => {
    localStorage.setItem('user_token', JSON.stringify(user))
  }, [user])


  useEffect(() => {
    const asyncFunc = async () => {
      if (profile) {
        const res = await fetch(`https://izsvtx666llxfidurfiy7maqqy0aydoc.lambda-url.ca-central-1.on.aws?email=${profile.email}&auth_token=${user.access_token}`,
          {
            headers: {
              "Content-Type": "application/json",
            }
          });

        if (res.status == 200) {
          const notes = await res.json();
          setNotes(notes);
        }
      };
    };
    asyncFunc();
  }, [profile]);





  useEffect(() => {
    localStorage.setItem('user', JSON.stringify(profile))
  }, [profile])






  useEffect(() => {
    if (user) {
      axios
        .get(`https://www.googleapis.com/oauth2/v1/userinfo?access_token=${user.access_token}`, {
          headers: {
            Authorization: `Bearer ${user.access_token}`,
            Accept: 'application/json'
          }
        })

        .then((res) => {

          setProfile(res.data);
        })
        .catch((err) => console.log(err));
    }
  },
    [user]
  );

  // console.log(user.access_token)




  const logOut = () => {
    googleLogout();
    setProfile(null);
  };






  useEffect(() => {
    localStorage.setItem(localStorageKey, JSON.stringify(notes));
  }, [notes]);





  useEffect(() => {
    if (currentNote < 0) {
      return;
    }
    if (!editMode) {
      navigate(`/notes/${currentNote + 1}`);
      return;
    }
    navigate(`/notes/${currentNote + 1}/edit`);
  }, [notes]);






  const saveNote = (note, index) => {
    note.body = note.body.replaceAll("<p><br></p>", "");
    setNotes([
      ...notes.slice(0, index),
      { ...note },
      ...notes.slice(index + 1),
    ]);
    setCurrentNote(index);
    setEditMode(false);
  };






  const deleteNote = async (index) => {
    const res = await fetch(
      `https://hsce6j6qia7ft2qzwujfcc4kgu0jkhtx.lambda-url.ca-central-1.on.aws?email=${profile.email}&auth_token=${user.access_token}`,
      {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ id: notes[index].id, email: notes[index].email })
      }
    );

    const data = await res.text();

    if (res.ok) {
      console.log("Note deleted successfully");
    } else {
      console.error("Failed to delete note:", data.message);
    }
    setNotes([...notes.slice(0, index), ...notes.slice(index + 1)]);
    setCurrentNote(0);
    setEditMode(false);
  };






  const addNote = async () => {
    const new_note = {
      email: profile.email,
      id: uuidv4(),
      title: "Untitled",
      body: "",
      when: currentDate(),
    }
    setNotes([new_note, ...notes,]);
    setEditMode(true);
    setCurrentNote(0);


    const res = await fetch(
      `https://xk2sn6nqldt6hbxk5zy3npl5km0tywvi.lambda-url.ca-central-1.on.aws?email=${profile.email}&auth_token=${user.access_token}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ ...new_note, email: profile.email })
      }
    );

  };






  return (
    <div id="container">
      <header>
        <aside>
          <button id="menu-button" onClick={() => setCollapse(!collapse)}>
            &#9776;
          </button>
        </aside>
        <div id="app-header">
          <h1>
            <Link to="/notes">Lotion</Link>
          </h1>
          <h6 id="app-moto">Like Notion, but worse.</h6>
        </div>
        <aside className="user">
          <div className="userOptions">
            {profile ? <p className="userName">{profile.name} (<button className="logOut" onClick={logOut}>Log Out</button>)</p> : ''}
          </div>
        </aside>
      </header>
      <div id="main-container" ref={mainContainerRef}>
        {profile ? (
          <>
            <aside id="sidebar" className={collapse ? "hidden" : null}>
              <header>
                <div id="notes-list-heading">
                  <h2>Notes</h2>
                  <button id="new-note-button" onClick={addNote}>
                    +
                  </button>
                </div>
              </header>
              <div id="notes-holder">
                <NoteList notes={notes} />
              </div>
            </aside>
            <div id="write-box">
              <Outlet context={[notes, saveNote, deleteNote, profile.email, user]} />
            </div>
          </>
        ) : (
          <div className="signIn">
            <button className="signIn" onClick={() => { login() }}>Sign into Lotion with <img src="https://i.imgur.com/SRq43uA.jpg" alt="Google Logo" height={20} ></img> </button>
          </div>
        )}
      </div>
    </div>
  );
}

export default Layout;