// SPDX-License-Identifier: GPL-3.0-only
#include "dinogame.hpp"

#include <QDir>
#include <QFile>
#include <QRandomGenerator>
#include <QStandardPaths>
#include <cmath>

namespace caelestia::services {

DinoGameBackend::DinoGameBackend(QObject* parent)
    : QObject(parent) {
    m_timer = new QTimer(this);
    m_timer->setTimerType(Qt::PreciseTimer);
    m_timer->setInterval(16);
    connect(m_timer, &QTimer::timeout, this, &DinoGameBackend::tick);

    readHighScore();
}

void DinoGameBackend::setIsDucking(bool val) {
    if (m_isDucking != val) {
        m_isDucking = val;
        emit isDuckingChanged();
    }
}

void DinoGameBackend::setWidth(qreal val) {
    if (m_width != val) {
        m_width = val;
        emit widthChanged();
    }
}

void DinoGameBackend::startGame() {
    if (m_isGameOver) {
        m_score = 0;
        emit scoreChanged();
        m_obstacles.clear();
        emit obstaclesChanged();
        m_clouds.clear();
        emit cloudsChanged();
        m_groundX = 0;
        emit groundXChanged();
        m_gameSpeed = 6.0;
        m_frameCount = 0;
        emit frameCountChanged();
        m_isInverted = false;
        emit isInvertedChanged();
    }

    m_isPlaying = true;
    emit isPlayingChanged();
    m_isGameOver = false;
    emit isGameOverChanged();

    m_dinoY = 0;
    emit dinoYChanged();
    m_dinoVelocityY = 0;

    emit gameStarted();
    m_timer->start();
}

void DinoGameBackend::gameOver() {
    m_isPlaying = false;
    emit isPlayingChanged();
    m_isGameOver = true;
    emit isGameOverChanged();

    m_timer->stop();
    emit gameDied();

    if (m_score > m_highScore) {
        m_highScore = m_score;
        emit highScoreChanged();
        writeHighScore();
    }
}

void DinoGameBackend::jump() {
    if (m_dinoY == 0 && m_isPlaying) {
        m_dinoVelocityY = m_jumpForce;
    } else if (!m_isPlaying) {
        startGame();
    }
}

void DinoGameBackend::tick() {
    m_dinoVelocityY += (m_isDucking ? m_duckGravity : m_gravity);
    m_dinoY += m_dinoVelocityY;
    if (m_dinoY > 0) {
        m_dinoY = 0;
        m_dinoVelocityY = 0;
    }
    emit dinoYChanged();

    m_frameCount++;
    emit frameCountChanged();

    m_score += 0.15;
    emit scoreChanged();

    m_groundX = std::fmod(m_groundX + m_gameSpeed, 2400.0);
    emit groundXChanged();

    QVariantList newClouds;
    for (const QVariant& v : m_clouds) {
        QVariantMap cloud = v.toMap();
        cloud[QStringLiteral("x")] = cloud[QStringLiteral("x")].toDouble() - m_gameSpeed * 0.25;
        if (cloud[QStringLiteral("x")].toDouble() + 92 > 0) {
            newClouds.append(cloud);
        }
    }
    m_clouds = newClouds;

    m_cloudTimer++;
    if (m_cloudTimer > 150 + QRandomGenerator::global()->generateDouble() * 200) {
        m_cloudTimer = 0;
        QVariantMap cloud;
        cloud[QStringLiteral("x")] = m_width;
        cloud[QStringLiteral("y")] = 10 + QRandomGenerator::global()->generateDouble() * 80;
        m_clouds.append(cloud);
    }
    emit cloudsChanged();

    bool inverted = (static_cast<int>(m_score / 700) % 2) == 1;
    if (m_isInverted != inverted) {
        m_isInverted = inverted;
        emit isInvertedChanged();
    }

    if (m_score >= 99999) {
        m_score = 99999;
        emit scoreChanged();
        gameOver();
        return;
    }

    if (std::floor(m_score) > 0 && static_cast<int>(std::floor(m_score)) % 100 == 0) {
        m_gameSpeed += 0.05;
    }

    QVariantList newObstacles;
    qreal dWidth = m_isDucking ? 59 : 44;
    qreal dHeight = m_isDucking ? 30 : 47;

    for (const QVariant& v : m_obstacles) {
        QVariantMap obs = v.toMap();
        obs[QStringLiteral("x")] = obs[QStringLiteral("x")].toDouble() - m_gameSpeed;

        qreal oX = obs[QStringLiteral("x")].toDouble() + 8;
        qreal oW = obs[QStringLiteral("width")].toDouble() - 16;
        qreal oYOffset = obs[QStringLiteral("yOffset")].toDouble();
        qreal oH = obs[QStringLiteral("height")].toDouble() - 16;

        qreal dX = 40;
        qreal dW = dWidth - 20;

        qreal dY = -30 - dHeight + m_dinoY + 10;
        qreal dH = dHeight - 15;
        qreal oY = -30 - obs[QStringLiteral("height")].toDouble() - oYOffset + 8;

        if (dX < oX + oW && dX + dW > oX && dY < oY + oH && dY + dH > oY) {
            gameOver();
            return;
        }

        if (obs[QStringLiteral("x")].toDouble() + obs[QStringLiteral("width")].toDouble() > 0) {
            newObstacles.append(obs);
        }
    }
    m_obstacles = newObstacles;

    m_obstacleTimer++;
    if (m_obstacleTimer > 60 + QRandomGenerator::global()->generateDouble() * 80) {
        m_obstacleTimer = 0;
        bool canSpawnBird = m_score > 300;
        QString spawnType = (canSpawnBird && QRandomGenerator::global()->generateDouble() > 0.7)
                                ? QStringLiteral("bird")
                                : (QRandomGenerator::global()->generateDouble() > 0.5 ? QStringLiteral("small")
                                                                                      : QStringLiteral("large"));

        QVariantMap newObs;
        newObs[QStringLiteral("x")] = m_width;
        newObs[QStringLiteral("type")] = spawnType;
        if (spawnType == QStringLiteral("bird")) {
            newObs[QStringLiteral("width")] = 46;
            newObs[QStringLiteral("height")] = 40;
            double heights[] = { 10, 35, 60 };
            newObs[QStringLiteral("yOffset")] = heights[QRandomGenerator::global()->bounded(3)];
        } else if (spawnType == QStringLiteral("small")) {
            newObs[QStringLiteral("width")] = 34;
            newObs[QStringLiteral("height")] = 35;
            newObs[QStringLiteral("yOffset")] = 0;
        } else {
            newObs[QStringLiteral("width")] = 25;
            newObs[QStringLiteral("height")] = 50;
            newObs[QStringLiteral("yOffset")] = 0;
        }
        m_obstacles.append(newObs);
    }
    emit obstaclesChanged();
}

void DinoGameBackend::readHighScore() {
    QString path = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) +
                   QStringLiteral("/caelestia/dino_highscore.txt");
    QFile f(path);
    if (f.open(QIODevice::ReadOnly)) {
        m_highScore = QString::fromUtf8(f.readAll()).trimmed().toDouble();
        emit highScoreChanged();
    }
}

void DinoGameBackend::writeHighScore() {
    QString dir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/caelestia");
    QDir().mkpath(dir);
    QFile f(dir + QStringLiteral("/dino_highscore.txt"));
    if (f.open(QIODevice::WriteOnly)) {
        f.write(QString::number(std::floor(m_highScore)).toUtf8());
    }
}

} // namespace caelestia::services
